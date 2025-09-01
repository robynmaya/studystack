class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user
  belongs_to :parent_comment, class_name: 'Comment', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: 'parent_comment_id', dependent: :destroy
  
  # Virtual associations for voting (would require additional tables in real app)
  # For now, we'll just provide methods that return 0
  
  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 5000 }
  validate :content_not_empty_or_whitespace
  
  # Scopes
  scope :top_level, -> { where(parent_comment_id: nil) }
  scope :replies, -> { where.not(parent_comment_id: nil) }
  scope :active, -> { where(is_deleted: false) }
  scope :deleted, -> { where(is_deleted: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :for_commentable, ->(commentable) { where(commentable: commentable) }
  
  # Methods
  def reply?
    parent_comment_id.present?
  end
  
  def top_level?
    parent_comment_id.nil?
  end
  
  def deleted?
    is_deleted?
  end
  
  def soft_delete!
    update!(is_deleted: true, content: '[Comment deleted]')
  end
  
  def restore!
    update!(is_deleted: false)
  end
  
  def reply_count
    replies.active.count
  end
  
  def thread_depth
    return 0 if top_level?
    1 + (parent_comment&.thread_depth || 0)
  end
  
  def can_be_replied_to?(max_depth = 5)
    thread_depth < max_depth
  end
  
  # Virtual methods for voting (would be backed by actual tables in production)
  def helpful_votes_count
    0 # Placeholder - would query comment_votes table
  end
  
  def not_helpful_votes_count
    0 # Placeholder - would query comment_votes table
  end
  
  def comment_votes
    [] # Placeholder - would return actual vote records
  end
  
  def comment_reports
    [] # Placeholder - would return actual report records
  end
  
  private
  
  def content_not_empty_or_whitespace
    if content.present? && content.strip.empty?
      errors.add(:content, 'cannot be empty or contain only whitespace')
    end
  end
end
