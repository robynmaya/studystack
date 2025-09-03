class Tip < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'
  belongs_to :tippable, polymorphic: true, optional: true # can be LiveStream, Message, Document, etc.
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending successful failed refunded] }
  validates :sender, presence: true
  validates :recipient, presence: true
  validate :sender_and_recipient_different
  validate :recipient_is_creator
  
  scope :successful, -> { where(status: 'successful') }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  scope :refunded, -> { where(status: 'refunded') }
  scope :by_sender, ->(user) { where(sender: user) }
  scope :by_recipient, ->(user) { where(recipient: user) }
  scope :this_month, -> { where(created_at: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :recent, -> { order(created_at: :desc) }
  
  def successful?
    status == 'successful'
  end
  
  def pending?
    status == 'pending'
  end
  
  def failed?
    status == 'failed'
  end
  
  def refunded?
    status == 'refunded'
  end
  
  def net_amount
    return 0 unless successful?
    amount - platform_fee
  end
  
  def platform_fee_percentage
    5.0 # 5% platform fee
  end
  
  def calculate_platform_fee
    (amount * platform_fee_percentage / 100.0).round(2)
  end
  
  def process_tip!
    # In real implementation, process with Stripe
    update!(
      status: 'successful',
      platform_fee: calculate_platform_fee,
      processed_at: Time.current
    )
  end
  
  private
  
  def sender_and_recipient_different
    errors.add(:recipient, "cannot be the same as sender") if sender_id == recipient_id
  end
  
  def recipient_is_creator
    errors.add(:recipient, "must be a creator") if recipient && !recipient.creator?
  end
end
