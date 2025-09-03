class StreamViewer < ApplicationRecord
  belongs_to :live_stream
  belongs_to :user
  
  validates :user_id, uniqueness: { scope: :live_stream_id }
  
  scope :active, -> { where(left_at: nil) }
  scope :inactive, -> { where.not(left_at: nil) }
  
  def active?
    left_at.nil?
  end
  
  def viewing_duration_minutes
    end_time = left_at || Time.current
    return 0 unless joined_at
    ((end_time - joined_at) / 1.minute).round
  end
end
