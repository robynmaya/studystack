class SubscriptionPaymentService
  def initialize(subscription, payment_method_id)
    @subscription = subscription
    @payment_method_id = payment_method_id
  end
  
  def process
    begin
      # Create or retrieve Stripe customer
      stripe_customer = ensure_stripe_customer
      
      # Attach payment method to customer
      Stripe::PaymentMethod.attach(@payment_method_id, { customer: stripe_customer.id })
      
      # Create Stripe subscription
      stripe_subscription = Stripe::Subscription.create({
        customer: stripe_customer.id,
        items: [{
          price_data: {
            currency: 'usd',
            product_data: {
              name: "Subscription to #{@subscription.creator.full_name}",
            },
            unit_amount: (@subscription.monthly_price * 100).to_i, # Convert to cents
            recurring: {
              interval: interval_for_billing_cycle(@subscription.billing_cycle)
            }
          }
        }],
        default_payment_method: @payment_method_id,
        metadata: {
          subscription_id: @subscription.id,
          creator_id: @subscription.creator.id,
          subscriber_id: @subscription.subscriber.id
        }
      })
      
      { success: true, stripe_subscription_id: stripe_subscription.id }
      
    rescue Stripe::CardError => e
      { success: false, error: e.user_message }
    rescue Stripe::StripeError => e
      { success: false, error: 'Subscription processing error' }
    rescue => e
      { success: false, error: 'Unexpected error occurred' }
    end
  end
  
  private
  
  def ensure_stripe_customer
    if @subscription.subscriber.stripe_customer_id.present?
      Stripe::Customer.retrieve(@subscription.subscriber.stripe_customer_id)
    else
      customer = Stripe::Customer.create({
        email: @subscription.subscriber.email,
        name: @subscription.subscriber.full_name,
        metadata: {
          user_id: @subscription.subscriber.id
        }
      })
      
      @subscription.subscriber.update!(stripe_customer_id: customer.id)
      customer
    end
  end
  
  def interval_for_billing_cycle(billing_cycle)
    case billing_cycle
    when 'monthly'
      'month'
    when 'quarterly'
      { interval: 'month', interval_count: 3 }
    when 'yearly'
      'year'
    else
      'month'
    end
  end
end
