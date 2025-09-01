# Create: rails generate migration CreateSubscriptions
class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :subscriber, null: false, foreign_key: { to_table: :users }
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :stripe_subscription_id, null: false
      t.string :status, null: false # active, canceled, past_due, incomplete
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.decimal :monthly_price, precision: 8, scale: 2, null: false
      t.timestamps
      
      t.index :stripe_subscription_id, unique: true
      t.index [:subscriber_id, :creator_id], unique: true
      t.index :status
    end
    
    add_check_constraint :subscriptions, 'subscriber_id != creator_id',
                         name: 'subscriptions_no_self_subscribe'
  end
end