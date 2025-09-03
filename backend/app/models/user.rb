class User < ApplicationRecord
  has_secure_password
  
  # Document relationships
  has_many :documents, dependent: :destroy
  
  # Following relationships
  has_many :following_relationships, class_name: 'UserFollow', foreign_key: 'user_id', dependent: :destroy
  has_many :following, through: :following_relationships, source: :target
  has_many :follower_relationships, class_name: 'UserFollow', foreign_key: 'target_id', dependent: :destroy
  has_many :followers, through: :follower_relationships, source: :user
  
  # Subscription relationships
  has_many :subscriber_subscriptions, class_name: 'Subscription', foreign_key: 'subscriber_id', dependent: :destroy
  has_many :creator_subscriptions, class_name: 'Subscription', foreign_key: 'creator_id', dependent: :destroy
  has_many :subscribed_to, through: :subscriber_subscriptions, source: :creator
  has_many :subscribers, through: :creator_subscriptions, source: :subscriber
  
  # Transaction relationships
  has_many :purchases, class_name: 'Transaction', foreign_key: 'buyer_id', dependent: :destroy
  has_many :sales, class_name: 'Transaction', foreign_key: 'seller_id', dependent: :destroy
  
  # Comment relationships
  has_many :comments, dependent: :destroy
  has_many :comment_votes, dependent: :destroy
  has_many :comment_reports, dependent: :destroy
  
  # Messaging relationships
  has_many :creator_conversations, class_name: 'Conversation', foreign_key: 'creator_id', dependent: :destroy
  has_many :subscriber_conversations, class_name: 'Conversation', foreign_key: 'subscriber_id', dependent: :destroy
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy
  
  # Live streaming relationships
  has_many :live_streams, foreign_key: 'creator_id', dependent: :destroy
  has_many :stream_viewers, dependent: :destroy
  has_many :watched_streams, through: :stream_viewers, source: :live_stream
  
  # Tip relationships
  has_many :sent_tips, class_name: 'Tip', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_tips, class_name: 'Tip', foreign_key: 'recipient_id', dependent: :destroy
  
  # Notification relationships
  has_many :notifications, dependent: :destroy
  has_many :triggered_notifications, class_name: 'Notification', foreign_key: 'actor_id', dependent: :destroy
  
  # Social media relationships
  has_many :posts, dependent: :destroy
  has_many :post_likes, dependent: :destroy
  has_many :liked_posts, through: :post_likes, source: :post

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :stripe_customer_id, uniqueness: true, allow_nil: true
  
  # Scopes
  scope :creators, -> { where(is_creator_enabled: true) }
  scope :public_profiles, -> { where(has_public_profile: true) }
  scope :with_subscriptions, -> { joins(:creator_subscriptions).distinct }
  
  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def creator?
    is_creator_enabled?
  end
  
  def public_profile?
    has_public_profile?
  end
  
  def following?(user)
    following.include?(user)
  end
  
  def follow!(user)
    return false if user == self
    following_relationships.create!(target: user)
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def unfollow!(user)
    following_relationships.find_by(target: user)&.destroy
  end
  
  def subscribed_to?(creator)
    subscriber_subscriptions.active.exists?(creator: creator)
  end
  
  def follower_count
    followers.count
  end
  
  def following_count
    following.count
  end
  
  def subscriber_count
    subscribers.count
  end
  
  def total_earnings
    sales.successful.sum(:amount) - sales.successful.sum(:platform_fee)
  end
  
  def monthly_earnings
    sales.successful.this_month.sum(:amount) - sales.successful.this_month.sum(:platform_fee)
  end
  
  def document_count
    documents.count
  end
  
  def video_count
    documents.videos.count
  end
  
  # Virtual method for default subscription price
  def default_subscription_price
    9.99 # Default price - in production this would be a database field
  end
end
