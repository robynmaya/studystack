class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :subscriber, null: false, foreign_key: { to_table: :users }
      t.boolean :is_archived, default: false

      t.timestamps
    end
    
    add_index :conversations, [:creator_id, :subscriber_id], unique: true
    add_check_constraint :conversations, 'creator_id != subscriber_id',
                         name: 'conversations_no_self_conversation'
  end
end
