class PaymentService
  def initialize(transaction, payment_method_id)
    @transaction = transaction
    @payment_method_id = payment_method_id
  end
  
  def process
    begin
      # Create Stripe payment intent
      payment_intent = Stripe::PaymentIntent.create({
        amount: (@transaction.amount * 100).to_i, # Convert to cents
        currency: 'usd',
        payment_method: @payment_method_id,
        confirmation_method: 'manual',
        confirm: true,
        metadata: {
          transaction_id: @transaction.id,
          document_id: @transaction.document.id,
          buyer_id: @transaction.buyer.id,
          seller_id: @transaction.seller.id
        }
      })
      
      if payment_intent.status == 'succeeded'
        @transaction.update!(
          status: 'successful',
          stripe_payment_intent_id: payment_intent.id,
          payment_method: determine_payment_method(payment_intent.payment_method)
        )
        
        # Increment download count
        @transaction.document.increment!(:download_count)
        
        { success: true, payment_intent: payment_intent }
      else
        @transaction.update!(status: 'failed')
        { success: false, error: 'Payment failed' }
      end
      
    rescue Stripe::CardError => e
      @transaction.update!(status: 'failed')
      { success: false, error: e.user_message }
    rescue Stripe::StripeError => e
      @transaction.update!(status: 'failed')
      { success: false, error: 'Payment processing error' }
    rescue => e
      @transaction.update!(status: 'failed')
      { success: false, error: 'Unexpected error occurred' }
    end
  end
  
  private
  
  def determine_payment_method(stripe_payment_method)
    case stripe_payment_method.type
    when 'card'
      "#{stripe_payment_method.card.brand.capitalize} ending in #{stripe_payment_method.card.last4}"
    else
      stripe_payment_method.type.humanize
    end
  end
end
