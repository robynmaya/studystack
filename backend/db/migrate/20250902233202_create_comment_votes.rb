class CreateCommentVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :comment_votes do |t|
      t.references :comment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :vote_type, null: false

      t.timestamps
    end
    
    # Ensure one vote per user per comment
    add_index :comment_votes, [:comment_id, :user_id], unique: true
    
    # Validate vote_type values
    add_check_constraint :comment_votes, "vote_type IN ('helpful', 'not_helpful')", name: 'comment_votes_valid_vote_type'
  end
end
