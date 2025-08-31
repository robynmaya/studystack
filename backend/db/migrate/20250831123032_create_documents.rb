class CreateDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :documents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :file_path, null: false
      t.integer :file_size_bytes, null: false
      t.string :file_type, null: false
      t.string :access_level, default: 'public'
      t.decimal :price, precision: 8, scale: 2, default: 0.00
      t.string :subject
      t.string :school
      t.string :document_type
      t.string :folder_name
      t.json :tags
      t.integer :download_count, default: 0
      t.decimal :rating_average, precision: 3, scale: 2, default: 0.00
      t.integer :rating_count, default: 0
      t.boolean :is_featured, default: false
      t.text :searchable_content
      t.timestamps
      
      t.index :subject
      t.index :school
      t.index :created_at
      t.index :is_featured, where: 'is_featured = true'
    end
  end
end