class AddMissingDefaultValues < ActiveRecord::Migration[8.0]
  def change
    # Add default values for subscription status
    change_column_default :subscriptions, :status, from: nil, to: 'incomplete'
    
    # Add default values for transaction status  
    change_column_default :transactions, :status, from: nil, to: 'pending'
    
    # Add default values for user boolean fields
    change_column_default :users, :is_creator_enabled, from: nil, to: false
    change_column_default :users, :has_public_profile, from: nil, to: false
  end
end
