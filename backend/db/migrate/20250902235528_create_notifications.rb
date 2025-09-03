class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :body
      t.datetime :read_at
      t.references :notifiable, polymorphic: true, null: true

      t.timestamps
    end
    
    add_index :notifications, :notification_type
    add_index :notifications, :read_at
    add_index :notifications, [:notifiable_type, :notifiable_id]
  end
end
