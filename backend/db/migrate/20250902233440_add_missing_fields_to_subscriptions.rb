class AddMissingFieldsToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :billing_cycle, :string, default: 'monthly'
    add_column :subscriptions, :start_date, :datetime
    add_column :subscriptions, :end_date, :datetime
    add_column :subscriptions, :cancelled_at, :datetime
    
    # Add indexes for performance
    add_index :subscriptions, :billing_cycle
    add_index :subscriptions, :start_date
    add_index :subscriptions, :end_date
    add_index :subscriptions, :cancelled_at
    
    # Add constraint for billing_cycle
    add_check_constraint :subscriptions, "billing_cycle IN ('monthly', 'quarterly', 'yearly')", name: 'subscriptions_valid_billing_cycle'
  end
end
