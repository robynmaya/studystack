class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :post_type, default: 'text'
      t.string :access_level, default: 'public'
      t.string :image_url
      t.string :video_url

      t.timestamps
    end
    
    add_index :posts, :post_type
    add_index :posts, :access_level
    add_index :posts, :created_at
  end
end
