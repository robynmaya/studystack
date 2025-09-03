class LiveStream < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :stream_viewers, dependent: :destroy
  has_many :stream_messages, dependent: :destroy
  has_many :stream_tips, dependent: :destroy
  has_many :viewers, through: :stream_viewers, source: :user
  
  validates :title, presence: true, length: { maximum: 200 }
  validates :status, inclusion: { in: %w[scheduled live ended] }
  validates :creator, presence: true
  validate :creator_is_creator
  
  scope :live, -> { where(status: 'live') }
  scope :scheduled, -> { where(status: 'scheduled') }
  scope :ended, -> { where(status: 'ended') }
  scope :by_creator, ->(creator) { where(creator: creator) }
  scope :recent, -> { order(started_at: :desc) }
  scope :popular, -> { joins(:stream_viewers).group(:id).order('COUNT(stream_viewers.id) DESC') }
  
  def live?
    status == 'live'
  end
  
  def scheduled?
    status == 'scheduled'
  end
  
  def ended?
    status == 'ended'
  end
  
  def current_viewer_count
    return 0 unless live?
    stream_viewers.active.count
  end
  
  def total_tips_amount
    stream_tips.sum(:amount)
  end
  
  def duration_minutes
    return 0 unless ended_at && started_at
    ((ended_at - started_at) / 1.minute).round
  end
  
  def start_stream!
    update!(status: 'live', started_at: Time.current)
  end
  
  def end_stream!
    update!(status: 'ended', ended_at: Time.current)
    stream_viewers.update_all(left_at: Time.current)
  end
  
  def add_viewer(user)
    stream_viewers.find_or_create_by(user: user) do |sv|
      sv.joined_at = Time.current
    end
  end
  
  def remove_viewer(user)
    viewer = stream_viewers.find_by(user: user)
    viewer&.update!(left_at: Time.current)
  end
  
  private
  
  def creator_is_creator
    errors.add(:creator, "must be a creator") if creator && !creator.creator?
  end
end
