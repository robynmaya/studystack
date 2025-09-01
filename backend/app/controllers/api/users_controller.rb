class Api::UsersController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]
  before_action :set_user, only: [:show, :follow, :unfollow]
  before_action :authorize_self!, only: [:update, :destroy, :creator_stats]
  
  # GET /api/users
  def index
    @users = User.public_profiles.includes(:documents)
    
    # Apply filters
    @users = @users.creators if params[:creators_only] == 'true'
    @users = @users.with_subscriptions if params[:with_subscriptions] == 'true'
    @users = @users.where('first_name ILIKE ? OR last_name ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    
    # Apply sorting
    case params[:sort_by]
    when 'followers'
      @users = @users.joins(:follower_relationships).group('users.id').order('COUNT(user_follows.id) DESC')
    when 'documents'
      @users = @users.joins(:documents).group('users.id').order('COUNT(documents.id) DESC')
    when 'recent'
      @users = @users.order(created_at: :desc)
    else
      @users = @users.order(:first_name, :last_name)
    end
    
    # Pagination
    @users = @users.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      users: @users.map { |user| user_json(user) },
      pagination: pagination_json(@users)
    }
  end
  
  # GET /api/users/:id
  def show
    unless @user.public_profile? || @user == current_user
      return render json: { error: 'Profile is private' }, status: :forbidden
    end
    
    render json: { user: user_json(@user, detailed: true) }
  end
  
  # GET /api/users/:id/documents
  def documents
    @user = User.find(params[:id])
    
    unless @user.public_profile? || @user == current_user
      return render json: { error: 'Profile is private' }, status: :forbidden
    end
    
    @documents = @user.documents.includes(:user)
    
    # Apply filters based on access level
    unless @user == current_user
      @documents = @documents.where(access_level: 'public')
    end
    
    @documents = @documents.by_subject(params[:subject]) if params[:subject].present?
    @documents = @documents.by_document_type(params[:document_type]) if params[:document_type].present?
    @documents = @documents.videos if params[:videos_only] == 'true'
    
    # Pagination
    @documents = @documents.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      documents: @documents.map { |doc| document_json(doc) },
      pagination: pagination_json(@documents)
    }
  end
  
  # GET /api/users/me
  def me
    return render json: { error: 'Not authenticated' }, status: :unauthorized unless current_user
    
    render json: { user: user_json(current_user, detailed: true, private: true) }
  end
  
  # PATCH/PUT /api/users/:id
  def update
    if current_user.update(user_params)
      render json: { user: user_json(current_user, detailed: true, private: true) }
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end
  
  # POST /api/users/:id/follow
  def follow
    if current_user.follow!(@user)
      render json: { 
        message: 'Successfully followed user',
        following: true,
        follower_count: @user.follower_count
      }
    else
      render json: { error: 'Unable to follow user' }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/users/:id/follow
  def unfollow
    if current_user.unfollow!(@user)
      render json: { 
        message: 'Successfully unfollowed user',
        following: false,
        follower_count: @user.follower_count
      }
    else
      render json: { error: 'Unable to unfollow user' }, status: :unprocessable_entity
    end
  end
  
  # GET /api/users/:id/following
  def following
    @user = User.find(params[:id])
    
    unless @user.public_profile? || @user == current_user
      return render json: { error: 'Profile is private' }, status: :forbidden
    end
    
    @following = @user.following.includes(:documents)
    @following = @following.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      users: @following.map { |user| user_json(user) },
      pagination: pagination_json(@following)
    }
  end
  
  # GET /api/users/:id/followers
  def followers
    @user = User.find(params[:id])
    
    unless @user.public_profile? || @user == current_user
      return render json: { error: 'Profile is private' }, status: :forbidden
    end
    
    @followers = @user.followers.includes(:documents)
    @followers = @followers.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      users: @followers.map { |user| user_json(user) },
      pagination: pagination_json(@followers)
    }
  end
  
  # GET /api/users/:id/creator_stats
  def creator_stats
    unless current_user.creator?
      return render json: { error: 'User is not a creator' }, status: :forbidden
    end
    
    stats = {
      total_documents: current_user.document_count,
      total_videos: current_user.video_count,
      total_downloads: current_user.documents.sum(:download_count),
      total_earnings: current_user.total_earnings,
      monthly_earnings: current_user.monthly_earnings,
      subscriber_count: current_user.subscriber_count,
      follower_count: current_user.follower_count,
      recent_transactions: current_user.sales.successful.recent.limit(10).map { |t| transaction_json(t) },
      top_documents: current_user.documents.popular.limit(5).map { |d| document_json(d) }
    }
    
    render json: { stats: stats }
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def authorize_self!
    @user = User.find(params[:id]) if params[:id]
    unless @user == current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
  
  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :bio, :profile_image_url,
      :has_public_profile, :is_creator_enabled, :location,
      :website_url, :twitter_handle, :linkedin_url
    )
  end
  
  def user_json(user, detailed: false, private: false)
    json = {
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      profile_image_url: user.profile_image_url,
      is_creator: user.creator?,
      follower_count: user.follower_count,
      following_count: user.following_count,
      document_count: user.document_count,
      created_at: user.created_at
    }
    
    if detailed
      json.merge!(
        bio: user.bio,
        location: user.location,
        website_url: user.website_url,
        twitter_handle: user.twitter_handle,
        linkedin_url: user.linkedin_url,
        video_count: user.video_count
      )
      
      # Add following status if viewing as another user
      if current_user && user != current_user
        json[:is_following] = current_user.following?(user)
        json[:is_subscribed] = current_user.subscribed_to?(user) if user.creator?
      end
    end
    
    # Add private fields for self
    if private && user == current_user
      json.merge!(
        email: user.email,
        has_public_profile: user.has_public_profile,
        is_creator_enabled: user.is_creator_enabled,
        stripe_customer_id: user.stripe_customer_id,
        subscriber_count: user.subscriber_count,
        total_earnings: user.total_earnings,
        monthly_earnings: user.monthly_earnings
      )
    end
    
    json
  end
  
  def document_json(document)
    {
      id: document.id,
      title: document.title,
      description: document.description,
      file_type: document.file_type,
      file_size_mb: document.file_size_mb,
      price: document.price,
      subject: document.subject,
      document_type: document.document_type,
      download_count: document.download_count,
      rating_average: document.rating_average,
      created_at: document.created_at,
      thumbnail_url: document.thumbnail_url
    }
  end
  
  def transaction_json(transaction)
    {
      id: transaction.id,
      amount: transaction.amount,
      seller_earnings: transaction.seller_earnings,
      document_title: transaction.document&.title,
      buyer_name: transaction.buyer.full_name,
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
end
