class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'
  
  validates :content, presence: true, length: { maximum: 5000 }
  validates :message_type, inclusion: { in: %w[text image video tip] }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :by_sender, ->(user) { where(sender: user) }
  scope :text_messages, -> { where(message_type: 'text') }
  scope :media_messages, -> { where(message_type: ['image', 'video']) }
  scope :tips, -> { where(message_type: 'tip') }
  
  def read?
    read_at.present?
  end
  
  def unread?
    read_at.nil?
  end
  
  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end
  
  def tip?
    message_type == 'tip'
  end
  
  def media?
    %w[image video].include?(message_type)
  end
  
  def text?
    message_type == 'text'
  end
end
