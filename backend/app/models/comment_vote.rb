class CommentVote < ApplicationRecord
  belongs_to :comment
  belongs_to :user
  
  # Validations
  validates :vote_type, inclusion: { in: %w[helpful not_helpful] }
  validates :user_id, uniqueness: { scope: :comment_id }
  
  # Scopes
  scope :helpful, -> { where(vote_type: 'helpful') }
  scope :not_helpful, -> { where(vote_type: 'not_helpful') }
  scope :by_user, ->(user) { where(user: user) }
  scope :for_comment, ->(comment) { where(comment: comment) }
  
  # Methods
  def helpful?
    vote_type == 'helpful'
  end
  
  def not_helpful?
    vote_type == 'not_helpful'
  end
end
