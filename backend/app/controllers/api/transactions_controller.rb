class Api::TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [:show, :refund]
  before_action :authorize_participant!, only: [:show, :refund]
  
  # GET /api/transactions
  def index
    @transactions = current_user.purchases.includes(:seller, :document)
    
    # Apply filters
    @transactions = @transactions.successful if params[:status] == 'successful'
    @transactions = @transactions.failed if params[:status] == 'failed'
    @transactions = @transactions.refunded if params[:status] == 'refunded'
    @transactions = @transactions.where(transaction_type: params[:type]) if params[:type].present?
    
    # Date range filter
    if params[:start_date].present?
      @transactions = @transactions.where('created_at >= ?', Date.parse(params[:start_date]))
    end
    if params[:end_date].present?
      @transactions = @transactions.where('created_at <= ?', Date.parse(params[:end_date]))
    end
    
    # Apply sorting
    case params[:sort_by]
    when 'recent'
      @transactions = @transactions.order(created_at: :desc)
    when 'amount_high'
      @transactions = @transactions.order(amount: :desc)
    when 'amount_low'
      @transactions = @transactions.order(:amount)
    else
      @transactions = @transactions.order(created_at: :desc)
    end
    
    # Pagination
    @transactions = @transactions.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      transactions: @transactions.map { |txn| transaction_json(txn) },
      pagination: pagination_json(@transactions),
      summary: {
        total_spent: current_user.purchases.successful.sum(:amount),
        total_purchases: current_user.purchases.successful.count,
        this_month_spent: current_user.purchases.successful.this_month.sum(:amount)
      }
    }
  end
  
  # GET /api/transactions/sales
  def sales
    @transactions = current_user.sales.includes(:buyer, :document)
    
    # Apply filters
    @transactions = @transactions.successful if params[:status] == 'successful'
    @transactions = @transactions.failed if params[:status] == 'failed'
    @transactions = @transactions.refunded if params[:status] == 'refunded'
    @transactions = @transactions.where(transaction_type: params[:type]) if params[:type].present?
    
    # Date range filter
    if params[:start_date].present?
      @transactions = @transactions.where('created_at >= ?', Date.parse(params[:start_date]))
    end
    if params[:end_date].present?
      @transactions = @transactions.where('created_at <= ?', Date.parse(params[:end_date]))
    end
    
    # Apply sorting
    case params[:sort_by]
    when 'recent'
      @transactions = @transactions.order(created_at: :desc)
    when 'amount_high'
      @transactions = @transactions.order(amount: :desc)
    when 'amount_low'
      @transactions = @transactions.order(:amount)
    else
      @transactions = @transactions.order(created_at: :desc)
    end
    
    # Pagination
    @transactions = @transactions.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      transactions: @transactions.map { |txn| transaction_json(txn, seller_view: true) },
      pagination: pagination_json(@transactions),
      summary: {
        total_earned: current_user.total_earnings,
        total_sales: current_user.sales.successful.count,
        this_month_earned: current_user.monthly_earnings,
        pending_payouts: calculate_pending_payouts
      }
    }
  end
  
  # GET /api/transactions/:id
  def show
    render json: { transaction: transaction_json(@transaction, detailed: true) }
  end
  
  # POST /api/transactions/:id/refund
  def refund
    unless @transaction.can_refund?
      return render json: { error: 'Transaction cannot be refunded' }, status: :bad_request
    end
    
    # Only seller can initiate refunds
    unless @transaction.seller == current_user
      return render json: { error: 'Only seller can initiate refunds' }, status: :unauthorized
    end
    
    # Process refund with Stripe
    result = RefundService.new(@transaction, params[:reason]).process
    
    if result[:success]
      @transaction.update!(
        status: 'refunded',
        refunded_at: Time.current,
        refund_reason: params[:reason]
      )
      
      render json: { 
        message: 'Refund processed successfully',
        transaction: transaction_json(@transaction, detailed: true)
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end
  
  # GET /api/transactions/analytics
  def analytics
    # Revenue analytics for the current user
    end_date = Date.current
    start_date = end_date - 12.months
    
    # Monthly revenue breakdown
    monthly_revenue = current_user.sales.successful
      .where(created_at: start_date..end_date)
      .group("DATE_TRUNC('month', created_at)")
      .sum('amount - platform_fee')
      .transform_keys { |date| date.strftime('%Y-%m') }
    
    # Top selling documents
    top_documents = current_user.documents
      .joins(:transactions)
      .where(transactions: { status: 'successful' })
      .group('documents.id, documents.title')
      .order('COUNT(transactions.id) DESC')
      .limit(10)
      .pluck('documents.title', 'COUNT(transactions.id)', 'SUM(transactions.amount - transactions.platform_fee)')
      .map { |title, count, revenue| { title: title, sales_count: count, revenue: revenue } }
    
    # Payment method breakdown
    payment_methods = current_user.sales.successful
      .group(:payment_method)
      .count
    
    analytics = {
      monthly_revenue: monthly_revenue,
      total_revenue: current_user.total_earnings,
      total_transactions: current_user.sales.successful.count,
      average_transaction: current_user.sales.successful.average(:amount)&.round(2),
      top_documents: top_documents,
      payment_methods: payment_methods,
      refund_rate: calculate_refund_rate,
      conversion_metrics: {
        total_views: current_user.documents.sum(:view_count),
        total_downloads: current_user.documents.sum(:download_count),
        conversion_rate: calculate_conversion_rate
      }
    }
    
    render json: { analytics: analytics }
  end
  
  private
  
  def set_transaction
    @transaction = Transaction.find(params[:id])
  end
  
  def authorize_participant!
    unless @transaction.buyer == current_user || @transaction.seller == current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
  
  def transaction_json(transaction, detailed: false, seller_view: false)
    json = {
      id: transaction.id,
      amount: transaction.amount,
      platform_fee: transaction.platform_fee,
      seller_earnings: transaction.seller_earnings,
      status: transaction.status,
      transaction_type: transaction.transaction_type,
      payment_method: transaction.payment_method,
      created_at: transaction.created_at
    }
    
    # Add document info
    if transaction.document
      json[:document] = {
        id: transaction.document.id,
        title: transaction.document.title,
        file_type: transaction.document.file_type,
        file_size_mb: transaction.document.file_size_mb
      }
    end
    
    # Add counterparty info based on view
    if seller_view
      # Seller viewing their sales
      json[:buyer] = {
        id: transaction.buyer.id,
        full_name: transaction.buyer.full_name,
        profile_image_url: transaction.buyer.profile_image_url
      }
    else
      # Buyer viewing their purchases
      json[:seller] = {
        id: transaction.seller.id,
        full_name: transaction.seller.full_name,
        profile_image_url: transaction.seller.profile_image_url
      }
    end
    
    if detailed
      json.merge!(
        stripe_payment_intent_id: transaction.stripe_payment_intent_id,
        updated_at: transaction.updated_at,
        refunded_at: transaction.refunded_at,
        refund_reason: transaction.refund_reason,
        can_refund: transaction.can_refund?
      )
    end
    
    json
  end
  
  def pagination_json(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
  
  def calculate_pending_payouts
    # Calculate earnings from last 7 days that haven't been paid out yet
    current_user.sales.successful
      .where('created_at >= ?', 7.days.ago)
      .sum('amount - platform_fee')
  end
  
  def calculate_refund_rate
    total_sales = current_user.sales.successful.count
    total_refunds = current_user.sales.refunded.count
    
    return 0 if total_sales.zero?
    
    ((total_refunds.to_f / total_sales) * 100).round(2)
  end
  
  def calculate_conversion_rate
    total_views = current_user.documents.sum(:view_count)
    total_purchases = current_user.sales.successful.count
    
    return 0 if total_views.zero?
    
    ((total_purchases.to_f / total_views) * 100).round(2)
  end
end
