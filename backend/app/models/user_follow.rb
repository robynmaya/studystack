class UserFollow < ApplicationRecord
  belongs_to :user
  belongs_to :target, class_name: 'User'
  
  # Validations
  validates :user_id, uniqueness: { scope: :target_id }
  validate :cannot_follow_self
  
  # Scopes
  scope :by_user, ->(user) { where(user: user) }
  scope :by_target, ->(target) { where(target: target) }
  scope :recent, -> { order(created_at: :desc) }
  
  private
  
  def cannot_follow_self
    if user_id == target_id
      errors.add(:target, 'cannot follow yourself')
    end
  end
end
