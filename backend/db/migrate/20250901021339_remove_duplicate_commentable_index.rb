class RemoveDuplicateCommentableIndex < ActiveRecord::Migration[8.0]
  def change
    # Remove the duplicate index - keep the automatically generated one
    remove_index :comments, name: "index_comments_on_commentable_type_and_commentable_id"
  end
end
