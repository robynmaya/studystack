class Subscription < ApplicationRecord
  belongs_to :subscriber, class_name: 'User'
  belongs_to :creator, class_name: 'User'
  
  # Validations
  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[incomplete active past_due canceled unpaid] }
  validates :billing_cycle, inclusion: { in: %w[monthly quarterly yearly] }
  validates :monthly_price, numericality: { greater_than: 0 }
  validates :subscriber_id, uniqueness: { scope: :creator_id }
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: ['canceled', 'unpaid']) }
  scope :past_due, -> { where(status: 'past_due') }
  scope :cancelled, -> { where(status: 'canceled') }  # Add missing scope (British spelling)
  scope :canceled, -> { where(status: 'canceled') }   # Also support American spelling
  scope :expired, -> { where('end_date < ?', Time.current) }  # Add missing scope
  scope :by_creator, ->(creator) { where(creator: creator) }
  scope :by_subscriber, ->(subscriber) { where(subscriber: subscriber) }
  scope :by_billing_cycle, ->(cycle) { where(billing_cycle: cycle) }
  
  # Methods
  def active?
    status == 'active'
  end
  
  def canceled?
    status == 'canceled'
  end
  
  def cancelled?  # British spelling alias
    canceled?
  end
  
  def past_due?
    status == 'past_due'
  end
  
  def expired?
    end_date && end_date < Time.current
  end
  
  def monthly?
    billing_cycle == 'monthly'
  end
  
  def quarterly?
    billing_cycle == 'quarterly'
  end
  
  def yearly?
    billing_cycle == 'yearly'
  end
  
  def current_period_active?
    return false unless current_period_start && current_period_end
    Time.current.between?(current_period_start, current_period_end)
  end
  
  def days_until_renewal
    return nil unless current_period_end
    [(current_period_end.to_date - Date.current).to_i, 0].max
  end
  
  def cancel!
    update!(status: 'canceled', cancelled_at: Time.current)
  end
  
  def reactivate!
    update!(status: 'active', cancelled_at: nil)
  end
  
  # Calculate end date based on start date and billing cycle
  def calculate_end_date
    return nil unless start_date && billing_cycle
    
    case billing_cycle
    when 'monthly'
      start_date + 1.month
    when 'quarterly'
      start_date + 3.months
    when 'yearly'
      start_date + 1.year
    end
  end
  
  # Auto-set end_date when start_date or billing_cycle changes
  before_save :set_end_date, if: :start_date_or_billing_cycle_changed?
  
  private
  
  def start_date_or_billing_cycle_changed?
    start_date_changed? || billing_cycle_changed?
  end
  
  def set_end_date
    self.end_date = calculate_end_date if start_date && billing_cycle
  end
end
