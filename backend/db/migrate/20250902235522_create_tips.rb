class CreateTips < ActiveRecord::Migration[8.0]
  def change
    create_table :tips do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.string :status, default: 'pending'
      t.decimal :platform_fee, precision: 8, scale: 2, default: 0
      t.datetime :processed_at
      t.references :tippable, polymorphic: true, null: true

      t.timestamps
    end
    
    add_index :tips, :status
    add_index :tips, [:tippable_type, :tippable_id]
    add_check_constraint :tips, 'sender_id != recipient_id',
                         name: 'tips_no_self_tip'
  end
end
