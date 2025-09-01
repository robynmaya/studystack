class RefundService
  def initialize(transaction, reason = nil)
    @transaction = transaction
    @reason = reason
  end
  
  def process
    begin
      # Create Stripe refund
      refund = Stripe::Refund.create({
        payment_intent: @transaction.stripe_payment_intent_id,
        reason: stripe_reason,
        metadata: {
          transaction_id: @transaction.id,
          reason: @reason
        }
      })
      
      if refund.status == 'succeeded'
        # Decrement download count
        @transaction.document.decrement!(:download_count) if @transaction.document.download_count > 0
        
        { success: true, refund: refund }
      else
        { success: false, error: 'Refund failed' }
      end
      
    rescue Stripe::StripeError => e
      { success: false, error: 'Refund processing error' }
    rescue => e
      { success: false, error: 'Unexpected error occurred' }
    end
  end
  
  private
  
  def stripe_reason
    case @reason
    when 'duplicate', 'fraudulent'
      @reason
    else
      'requested_by_customer'
    end
  end
end
