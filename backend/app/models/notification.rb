class Notification < ApplicationRecord
  belongs_to :user  # recipient
  belongs_to :actor, class_name: 'User', optional: true  # who triggered the notification
  belongs_to :notifiable, polymorphic: true, optional: true  # what the notification is about
  
  validates :notification_type, inclusion: { 
    in: %w[new_subscriber new_message new_tip new_comment stream_started 
           document_purchased subscription_renewal payment_received] 
  }
  validates :title, presence: true, length: { maximum: 200 }
  validates :body, length: { maximum: 1000 }
  
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }
  
  def read?
    read_at.present?
  end
  
  def unread?
    read_at.nil?
  end
  
  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end
  
  def self.mark_all_as_read_for(user)
    user.notifications.unread.update_all(read_at: Time.current)
  end
  
  def self.create_new_subscriber_notification(creator, subscriber)
    create!(
      user: creator,
      actor: subscriber,
      notification_type: 'new_subscriber',
      title: 'New Subscriber!',
      body: "#{subscriber.full_name} just subscribed to your content"
    )
  end
  
  def self.create_new_tip_notification(creator, tipper, tip)
    create!(
      user: creator,
      actor: tipper,
      notifiable: tip,
      notification_type: 'new_tip',
      title: 'New Tip Received!',
      body: "#{tipper.full_name} sent you a $#{tip.amount} tip"
    )
  end
  
  def self.create_stream_started_notification(follower, creator, stream)
    create!(
      user: follower,
      actor: creator,
      notifiable: stream,
      notification_type: 'stream_started',
      title: 'Live Stream Started!',
      body: "#{creator.full_name} is now live: #{stream.title}"
    )
  end
end
