class CreateCommentReports < ActiveRecord::Migration[8.0]
  def change
    create_table :comment_reports do |t|
      t.references :comment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :reason, null: false
      t.text :description

      t.timestamps
    end
    
    # Ensure one report per user per comment
    add_index :comment_reports, [:comment_id, :user_id], unique: true
    
    # Validate reason values
    add_check_constraint :comment_reports, "reason IN ('spam', 'inappropriate', 'harassment', 'other')", name: 'comment_reports_valid_reason'
  end
end
