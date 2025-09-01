class ExpandDocumentTypesForVideo < ActiveRecord::Migration[8.0]
  def change
    # Add check constraint to ensure valid document types
    # This includes both traditional document types and video content types
    add_check_constraint :documents,
      "document_type IN ('study_guide', 'notes', 'practice_exam', 'textbook', 'summary', 
                         'lecture_video', 'tutorial_video', 'demo_video', 'explanation_video',
                         'animation', 'presentation', 'lab_recording', 'solved_problems',
                         'quiz_walkthrough', 'concept_explanation') OR document_type IS NULL",
      name: 'documents_valid_document_type'
  end
end
