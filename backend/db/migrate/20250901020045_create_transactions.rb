# Create: rails generate migration CreateTransactions
class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.references :document, null: true, foreign_key: true # null for tips/subscriptions
      t.string :stripe_payment_intent_id, null: false
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.decimal :platform_fee, precision: 8, scale: 2, null: false
      t.string :status, null: false # succeeded, failed, pending, canceled
      t.string :transaction_type, null: false # document_purchase, tip, subscription_payment
      t.timestamps
      
      t.index :stripe_payment_intent_id, unique: true
      t.index [:buyer_id, :created_at]
      t.index [:seller_id, :created_at]
      t.index :status
      t.index :transaction_type
    end
  end
end