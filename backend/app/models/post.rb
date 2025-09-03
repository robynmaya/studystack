class Post < ApplicationRecord
  belongs_to :user
  has_many :post_likes, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :likers, through: :post_likes, source: :user
  
  validates :content, presence: true, length: { maximum: 5000 }
  validates :post_type, inclusion: { in: %w[text image video poll announcement] }
  validates :access_level, inclusion: { in: %w[public subscribers_only] }
  
  scope :public_posts, -> { where(access_level: 'public') }
  scope :subscriber_posts, -> { where(access_level: 'subscribers_only') }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { joins(:post_likes).group(:id).order('COUNT(post_likes.id) DESC') }
  scope :by_type, ->(type) { where(post_type: type) }
  
  def public?
    access_level == 'public'
  end
  
  def subscribers_only?
    access_level == 'subscribers_only'
  end
  
  def likes_count
    post_likes.count
  end
  
  def comments_count
    comments.count
  end
  
  def liked_by?(user)
    return false unless user
    post_likes.exists?(user: user)
  end
  
  def accessible_by?(user)
    return true if public?
    return false unless user
    return true if user == self.user
    return user.subscribed_to?(self.user) if subscribers_only?
    false
  end
end
