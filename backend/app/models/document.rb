class Document < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  
  # Validations
  validates :title, :file_path, :file_type, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :file_size_bytes, numericality: { greater_than: 0 }
  validates :access_level, inclusion: { in: %w[public subscriber_only premium] }
  validates :document_type, inclusion: { 
    in: %w[study_guide notes practice_exam textbook summary lecture_video 
           tutorial_video demo_video explanation_video animation presentation 
           lab_recording solved_problems quiz_walkthrough concept_explanation],
    allow_nil: true
  }
  validates :rating_average, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 5 
  }
  validates :rating_count, :download_count, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_seconds, numericality: { greater_than_or_equal_to: 0 }
  
  # Scopes
  scope :featured, -> { where(is_featured: true) }
  scope :by_subject, ->(subject) { where(subject: subject) }
  scope :by_school, ->(school) { where(school: school) }
  scope :by_document_type, ->(type) { where(document_type: type) }
  scope :by_access_level, ->(level) { where(access_level: level) }
  scope :videos, -> { where("file_type LIKE 'video/%'") }
  scope :documents, -> { where("file_type NOT LIKE 'video/%'") }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(download_count: :desc) }
  scope :top_rated, -> { where('rating_count > 0').order(rating_average: :desc) }
  
  # Methods
  def video?
    file_type&.start_with?('video/')
  end
  
  def image?
    file_type&.start_with?('image/')
  end
  
  def free?
    price.zero?
  end
  
  def premium?
    access_level == 'premium'
  end
  
  def duration_in_minutes
    duration_seconds / 60.0
  end
  
  def file_size_mb
    (file_size_bytes / 1_024_000.0).round(2)
  end
end
