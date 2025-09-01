class Api::DocumentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_document, only: [:show, :update, :destroy, :purchase]
  before_action :authorize_owner!, only: [:update, :destroy]
  
  # GET /api/documents
  def index
    @documents = Document.includes(:user)
    
    # Apply filters
    @documents = @documents.by_subject(params[:subject]) if params[:subject].present?
    @documents = @documents.by_school(params[:school]) if params[:school].present?
    @documents = @documents.by_document_type(params[:document_type]) if params[:document_type].present?
    @documents = @documents.by_access_level(params[:access_level]) if params[:access_level].present?
    @documents = @documents.featured if params[:featured] == 'true'
    @documents = @documents.videos if params[:videos_only] == 'true'
    @documents = @documents.where('price <= ?', params[:max_price]) if params[:max_price].present?
    @documents = @documents.where('duration_seconds <= ?', params[:max_duration]) if params[:max_duration].present?
    
    # Apply sorting
    case params[:sort_by]
    when 'recent'
      @documents = @documents.recent
    when 'popular'
      @documents = @documents.popular
    when 'top_rated'
      @documents = @documents.top_rated
    when 'price_low'
      @documents = @documents.order(:price)
    when 'price_high'
      @documents = @documents.order(price: :desc)
    else
      @documents = @documents.recent
    end
    
    # Pagination
    @documents = @documents.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      documents: @documents.map { |doc| document_json(doc) },
      pagination: pagination_json(@documents)
    }
  end
  
  # GET /api/documents/:id
  def show
    # Check access permissions
    unless can_access_document?(@document)
      return render json: { error: 'Access denied' }, status: :forbidden
    end
    
    render json: { document: document_json(@document, detailed: true) }
  end
  
  # POST /api/documents
  def create
    @document = current_user.documents.build(document_params)
    
    if @document.save
      # Start video processing if it's a video
      VideoProcessingJob.perform_later(@document) if @document.video?
      
      render json: { document: document_json(@document) }, status: :created
    else
      render json: { errors: @document.errors }, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/documents/:id
  def update
    if @document.update(document_params)
      render json: { document: document_json(@document) }
    else
      render json: { errors: @document.errors }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/documents/:id
  def destroy
    @document.destroy
    head :no_content
  end
  
  # POST /api/documents/:id/purchase
  def purchase
    if @document.free?
      return render json: { error: 'Document is free' }, status: :bad_request
    end
    
    # Create transaction
    @transaction = Transaction.new(
      buyer: current_user,
      seller: @document.user,
      document: @document,
      amount: @document.price,
      platform_fee: calculate_platform_fee(@document.price),
      transaction_type: 'document_purchase'
    )
    
    # Process payment with Stripe
    result = PaymentService.new(@transaction, params[:payment_method_id]).process
    
    if result[:success]
      render json: { 
        transaction: transaction_json(@transaction),
        download_url: generate_download_url(@document)
      }
    else
      render json: { error: result[:error] }, status: :payment_required
    end
  end
  
  private
  
  def set_document
    @document = Document.find(params[:id])
  end
  
  def authorize_owner!
    unless @document.user == current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
  
  def can_access_document?(document)
    return true if document.access_level == 'public'
    return false unless current_user
    
    # Owner can always access
    return true if document.user == current_user
    
    # Check subscription for subscriber_only content
    if document.access_level == 'subscriber_only'
      return current_user.subscribed_to?(document.user)
    end
    
    # Check purchase for premium content
    if document.access_level == 'premium'
      return current_user.purchases.successful.exists?(document: document)
    end
    
    false
  end
  
  def document_params
    params.require(:document).permit(
      :title, :description, :file_path, :file_size_bytes, :file_type,
      :access_level, :price, :subject, :school, :document_type,
      :folder_name, :is_featured, :video_quality, :has_audio,
      tags: []
    )
  end
  
  def document_json(document, detailed: false)
    json = {
      id: document.id,
      title: document.title,
      description: document.description,
      file_type: document.file_type,
      file_size_mb: document.file_size_mb,
      price: document.price,
      subject: document.subject,
      school: document.school,
      document_type: document.document_type,
      tags: document.tags,
      download_count: document.download_count,
      rating_average: document.rating_average,
      rating_count: document.rating_count,
      is_featured: document.is_featured,
      created_at: document.created_at,
      user: {
        id: document.user.id,
        full_name: document.user.full_name,
        profile_image_url: document.user.profile_image_url
      }
    }
    
    # Add video-specific fields
    if document.video?
      json.merge!(
        duration_seconds: document.duration_seconds,
        duration_minutes: document.duration_in_minutes,
        thumbnail_url: document.thumbnail_url,
        video_quality: document.video_quality,
        has_audio: document.has_audio,
        processing_status: document.processing_status
      )
    end
    
    # Add detailed fields for single document view
    if detailed
      json.merge!(
        folder_name: document.folder_name,
        searchable_content: document.searchable_content,
        updated_at: document.updated_at
      )
    end
    
    json
  end
  
  def transaction_json(transaction)
    {
      id: transaction.id,
      amount: transaction.amount,
      platform_fee: transaction.platform_fee,
      seller_earnings: transaction.seller_earnings,
      status: transaction.status,
      created_at: transaction.created_at
    }
  end
  
  def pagination_json(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
  
  def calculate_platform_fee(amount)
    # 5% platform fee with $0.30 minimum
    [(amount * 0.05).round(2), 0.30].max
  end
  
  def generate_download_url(document)
    # Generate secure download URL
    Rails.application.routes.url_helpers.rails_blob_url(document.file_path, only_path: true)
  end
end
