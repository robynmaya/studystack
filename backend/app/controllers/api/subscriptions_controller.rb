class Api::SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription, only: [:show, :cancel, :update]
  before_action :authorize_participant!, only: [:show, :cancel, :update]
  
  # GET /api/subscriptions
  def index
    # Get user's subscriptions (as subscriber)
    @subscriptions = current_user.subscriber_subscriptions.includes(:creator, :subscriber)
    
    # Apply filters
    @subscriptions = @subscriptions.active if params[:status] == 'active'
    @subscriptions = @subscriptions.cancelled if params[:status] == 'cancelled'
    @subscriptions = @subscriptions.expired if params[:status] == 'expired'
    
    # Apply sorting
    case params[:sort_by]
    when 'recent'
      @subscriptions = @subscriptions.order(created_at: :desc)
    when 'expiring'
      @subscriptions = @subscriptions.active.order(:end_date)
    when 'price_high'
      @subscriptions = @subscriptions.order(monthly_price: :desc)
    when 'price_low'
      @subscriptions = @subscriptions.order(:monthly_price)
    else
      @subscriptions = @subscriptions.order(created_at: :desc)
    end
    
    # Pagination
    @subscriptions = @subscriptions.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      subscriptions: @subscriptions.map { |sub| subscription_json(sub) },
      pagination: pagination_json(@subscriptions)
    }
  end
  
  # GET /api/subscriptions/creator
  def creator_subscriptions
    unless current_user.creator?
      return render json: { error: 'User is not a creator' }, status: :forbidden
    end
    
    # Get subscriptions to current user (as creator)
    @subscriptions = current_user.creator_subscriptions.includes(:creator, :subscriber)
    
    # Apply filters
    @subscriptions = @subscriptions.active if params[:status] == 'active'
    @subscriptions = @subscriptions.cancelled if params[:status] == 'cancelled'
    @subscriptions = @subscriptions.expired if params[:status] == 'expired'
    
    # Apply sorting
    case params[:sort_by]
    when 'recent'
      @subscriptions = @subscriptions.order(created_at: :desc)
    when 'expiring'
      @subscriptions = @subscriptions.active.order(:end_date)
    when 'revenue_high'
      @subscriptions = @subscriptions.order(monthly_price: :desc)
    else
      @subscriptions = @subscriptions.order(created_at: :desc)
    end
    
    # Pagination
    @subscriptions = @subscriptions.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      subscriptions: @subscriptions.map { |sub| subscription_json(sub, creator_view: true) },
      pagination: pagination_json(@subscriptions),
      revenue_stats: {
        total_monthly_revenue: @subscriptions.active.sum(:monthly_price),
        total_subscribers: @subscriptions.active.count,
        new_this_month: @subscriptions.where('created_at >= ?', 1.month.ago).count
      }
    }
  end
  
  # GET /api/subscriptions/:id
  def show
    render json: { subscription: subscription_json(@subscription, detailed: true) }
  end
  
  # POST /api/subscriptions
  def create
    @creator = User.find(params[:creator_id])
    
    unless @creator.creator?
      return render json: { error: 'User is not a creator' }, status: :bad_request
    end
    
    if current_user.subscribed_to?(@creator)
      return render json: { error: 'Already subscribed to this creator' }, status: :conflict
    end
    
    @subscription = Subscription.new(
      subscriber: current_user,
      creator: @creator,
      monthly_price: subscription_params[:monthly_price] || @creator.default_subscription_price,
      billing_cycle: subscription_params[:billing_cycle] || 'monthly',
      start_date: Date.current
    )
    
    # Calculate end date based on billing cycle
    @subscription.end_date = calculate_end_date(@subscription.start_date, @subscription.billing_cycle)
    
    # Process payment with Stripe
    result = SubscriptionPaymentService.new(@subscription, params[:payment_method_id]).process
    
    if result[:success]
      @subscription.stripe_subscription_id = result[:stripe_subscription_id]
      @subscription.status = 'active'
      
      if @subscription.save
        render json: { subscription: subscription_json(@subscription) }, status: :created
      else
        render json: { errors: @subscription.errors }, status: :unprocessable_entity
      end
    else
      render json: { error: result[:error] }, status: :payment_required
    end
  end
  
  # PATCH/PUT /api/subscriptions/:id
  def update
    # Only allow updating billing cycle and payment method
    allowed_params = subscription_params.slice(:billing_cycle)
    
    if @subscription.update(allowed_params)
      # Update Stripe subscription if billing cycle changed
      if allowed_params[:billing_cycle].present?
        SubscriptionUpdateService.new(@subscription).update_billing_cycle
      end
      
      render json: { subscription: subscription_json(@subscription) }
    else
      render json: { errors: @subscription.errors }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/subscriptions/:id/cancel
  def cancel
    if @subscription.cancel!
      # Cancel on Stripe
      SubscriptionCancellationService.new(@subscription).cancel
      
      render json: { 
        message: 'Subscription cancelled successfully',
        subscription: subscription_json(@subscription)
      }
    else
      render json: { error: 'Unable to cancel subscription' }, status: :unprocessable_entity
    end
  end
  
  # POST /api/subscriptions/:id/reactivate
  def reactivate
    unless @subscription.cancelled?
      return render json: { error: 'Subscription is not cancelled' }, status: :bad_request
    end
    
    if @subscription.reactivate!
      # Reactivate on Stripe
      SubscriptionReactivationService.new(@subscription).reactivate
      
      render json: { 
        message: 'Subscription reactivated successfully',
        subscription: subscription_json(@subscription)
      }
    else
      render json: { error: 'Unable to reactivate subscription' }, status: :unprocessable_entity
    end
  end
  
  # GET /api/creators/:creator_id/subscription_info
  def creator_info
    @creator = User.find(params[:creator_id])
    
    unless @creator.creator?
      return render json: { error: 'User is not a creator' }, status: :bad_request
    end
    
    info = {
      creator: {
        id: @creator.id,
        full_name: @creator.full_name,
        profile_image_url: @creator.profile_image_url,
        bio: @creator.bio,
        subscriber_count: @creator.subscriber_count,
        document_count: @creator.document_count,
        video_count: @creator.video_count
      },
      subscription_options: {
        monthly_price: @creator.default_subscription_price || 9.99,
        billing_cycles: ['monthly', 'quarterly', 'yearly'],
        benefits: [
          'Access to subscriber-only content',
          'Early access to new uploads',
          'Direct messaging with creator',
          'Exclusive live sessions'
        ]
      }
    }
    
    # Add current subscription status if user is authenticated
    if current_user
      info[:current_subscription] = current_user.subscribed_to?(@creator)
      if info[:current_subscription]
        subscription = current_user.subscriber_subscriptions.active.find_by(creator: @creator)
        info[:subscription_details] = subscription_json(subscription) if subscription
      end
    end
    
    render json: info
  end
  
  private
  
  def set_subscription
    @subscription = Subscription.find(params[:id])
  end
  
  def authorize_participant!
    unless @subscription.subscriber == current_user || @subscription.creator == current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
  
  def subscription_params
    params.require(:subscription).permit(:monthly_price, :billing_cycle)
  end
  
  def subscription_json(subscription, detailed: false, creator_view: false)
    json = {
      id: subscription.id,
      monthly_price: subscription.monthly_price,
      billing_cycle: subscription.billing_cycle,
      status: subscription.status,
      start_date: subscription.start_date,
      end_date: subscription.end_date,
      created_at: subscription.created_at,
      updated_at: subscription.updated_at
    }
    
    # Add creator info for subscriber view
    unless creator_view
      json[:creator] = {
        id: subscription.creator.id,
        full_name: subscription.creator.full_name,
        profile_image_url: subscription.creator.profile_image_url
      }
    end
    
    # Add subscriber info for creator view
    if creator_view
      json[:subscriber] = {
        id: subscription.subscriber.id,
        full_name: subscription.subscriber.full_name,
        profile_image_url: subscription.subscriber.profile_image_url
      }
    end
    
    if detailed
      json.merge!(
        stripe_subscription_id: subscription.stripe_subscription_id,
        cancelled_at: subscription.cancelled_at,
        auto_renew: subscription.auto_renew?
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
  
  def calculate_end_date(start_date, billing_cycle)
    case billing_cycle
    when 'monthly'
      start_date + 1.month
    when 'quarterly'
      start_date + 3.months
    when 'yearly'
      start_date + 1.year
    else
      start_date + 1.month
    end
  end
end
