class Subscription < ApplicationRecord
  belongs_to :subscriber, class_name: 'User'
  belongs_to :creator, class_name: 'User'
  
  # Validations
  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[incomplete active past_due canceled unpaid] }
  validates :monthly_price, numericality: { greater_than: 0 }
  validates :subscriber_id, uniqueness: { scope: :creator_id }
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: ['canceled', 'unpaid']) }
  scope :past_due, -> { where(status: 'past_due') }
  scope :by_creator, ->(creator) { where(creator: creator) }
  scope :by_subscriber, ->(subscriber) { where(subscriber: subscriber) }
  
  # Methods
  def active?
    status == 'active'
  end
  
  def canceled?
    status == 'canceled'
  end
  
  def past_due?
    status == 'past_due'
  end
  
  def current_period_active?
    return false unless current_period_start && current_period_end
    Time.current.between?(current_period_start, current_period_end)
  end
  
  def days_until_renewal
    return nil unless current_period_end
    [(current_period_end.to_date - Date.current).to_i, 0].max
  end
end
