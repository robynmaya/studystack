class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false
      t.string :message_type, default: 'text'
      t.datetime :read_at

      t.timestamps
    end
    
    add_index :messages, :read_at
  end
end