class AddCreatorFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :profile_bio, :text
    add_column :users, :profile_image_url, :string
    add_column :users, :is_creator_enabled, :boolean
    add_column :users, :has_public_profile, :boolean
    add_column :users, :stripe_customer_id, :string

    add_index :users, :email, unique: true
    add_index :users, :stripe_customer_id, unique: true
  end
end
