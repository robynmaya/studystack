# Create: rails generate migration CreateComments
class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.references :parent_comment, null: true, foreign_key: { to_table: :comments }
      t.boolean :is_deleted, default: false
      t.timestamps
      
      # Note: t.references :commentable, polymorphic: true automatically creates
      # index on [:commentable_type, :commentable_id], so we don't need to add it manually
      t.index [:user_id, :created_at]
      t.index :is_deleted
    end
    
    add_check_constraint :comments, 'LENGTH(TRIM(content)) > 0',
                         name: 'comments_non_empty_content'
  end
end