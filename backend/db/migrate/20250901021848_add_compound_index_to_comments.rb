class AddCompoundIndexToComments < ActiveRecord::Migration[8.0]
  def change
    # Add compound index for optimal comment queries
    # This covers: find comments by type/id + sort by date in one index lookup
    add_index :comments, [:commentable_type, :commentable_id, :created_at], 
              name: 'index_comments_on_commentable_and_created_at'
  end
end
