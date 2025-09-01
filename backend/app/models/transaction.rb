class Transaction < ApplicationRecord
  belongs_to :buyer, class_name: 'User'
  belongs_to :seller, class_name: 'User'
  belongs_to :document, optional: true # null for tips/subscriptions
  
  # Validations
  validates :stripe_payment_intent_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending succeeded failed canceled] }
  validates :transaction_type, inclusion: { 
    in: %w[document_purchase tip subscription_payment] 
  }
  validates :amount, :platform_fee, numericality: { greater_than_or_equal_to: 0 }
  validates :amount, numericality: { greater_than: :platform_fee }
  
  # Scopes
  scope :successful, -> { where(status: 'succeeded') }
  scope :failed, -> { where(status: 'failed') }
  scope :pending, -> { where(status: 'pending') }
  scope :refunded, -> { where(status: 'refunded') }
  scope :by_buyer, ->(buyer) { where(buyer: buyer) }
  scope :by_seller, ->(seller) { where(seller: seller) }
  scope :by_type, ->(type) { where(transaction_type: type) }
  scope :document_purchases, -> { where(transaction_type: 'document_purchase') }
  scope :tips, -> { where(transaction_type: 'tip') }
  scope :subscription_payments, -> { where(transaction_type: 'subscription_payment') }
  scope :recent, -> { order(created_at: :desc) }
  scope :this_month, -> { where(created_at: Date.current.beginning_of_month..) }
  
  # Methods
  def succeeded?
    status == 'succeeded'
  end
  
  def failed?
    status == 'failed'
  end
  
  def pending?
    status == 'pending'
  end
  
  def seller_earnings
    amount - platform_fee
  end
  
  def platform_fee_percentage
    return 0 if amount.zero?
    (platform_fee / amount * 100).round(2)
  end
  
  def document_purchase?
    transaction_type == 'document_purchase'
  end
  
  def tip?
    transaction_type == 'tip'
  end
  
  def subscription_payment?
    transaction_type == 'subscription_payment'
  end
end
