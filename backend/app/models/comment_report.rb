class CommentReport < ApplicationRecord
  belongs_to :comment
  belongs_to :user
  
  # Validations
  validates :reason, inclusion: { in: %w[spam inappropriate harassment other] }
  validates :user_id, uniqueness: { scope: :comment_id }
  validates :description, length: { maximum: 1000 }
  
  # Scopes
  scope :by_reason, ->(reason) { where(reason: reason) }
  scope :by_user, ->(user) { where(user: user) }
  scope :for_comment, ->(comment) { where(comment: comment) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Methods
  def spam?
    reason == 'spam'
  end
  
  def inappropriate?
    reason == 'inappropriate'
  end
  
  def harassment?
    reason == 'harassment'
  end
  
  def other?
    reason == 'other'
  end
end
