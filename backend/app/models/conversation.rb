class Conversation < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  belongs_to :subscriber, class_name: 'User'
  has_many :messages, dependent: :destroy
  
  validates :creator_id, uniqueness: { scope: :subscriber_id }
  validates :creator, presence: true
  validates :subscriber, presence: true
  validate :participants_different
  validate :creator_is_creator
  
  scope :active, -> { where(is_archived: false) }
  scope :archived, -> { where(is_archived: true) }
  scope :unread_for, ->(user) { 
    joins(:messages).where(messages: { read_at: nil }).where.not(messages: { sender: user })
  }
  
  def other_participant(user)
    user == creator ? subscriber : creator
  end
  
  def unread_count_for(user)
    messages.where(read_at: nil).where.not(sender: user).count
  end
  
  def last_message
    messages.order(:created_at).last
  end
  
  def mark_as_read_for(user)
    messages.where(read_at: nil).where.not(sender: user).update_all(read_at: Time.current)
  end
  
  private
  
  def participants_different
    errors.add(:subscriber, "cannot be the same as creator") if creator_id == subscriber_id
  end
  
  def creator_is_creator
    errors.add(:creator, "must be a creator") if creator && !creator.creator?
  end
end
