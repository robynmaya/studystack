class AddVideoSupportToDocuments < ActiveRecord::Migration[8.0]
  def change
    # Add video-specific fields to documents table
    add_column :documents, :duration_seconds, :integer, default: 0
    add_column :documents, :thumbnail_url, :string
    add_column :documents, :video_quality, :string # 480p, 720p, 1080p
    add_column :documents, :has_audio, :boolean, default: true
    add_column :documents, :video_codec, :string # h264, h265, vp9
    add_column :documents, :processing_status, :string, default: 'pending'
    
    # Add indexes for video-specific queries
    add_index :documents, :duration_seconds
    add_index :documents, :processing_status
    add_index :documents, [:file_type, :duration_seconds], 
              name: 'index_documents_video_duration'
    
    # Add check constraints for video fields
    add_check_constraint :documents, 'duration_seconds >= 0',
                         name: 'documents_non_negative_duration'
  end
end
