class CreateUserFollows < ActiveRecord::Migration[7.0]
  def change
    create_table :user_follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :target, null: false, foreign_key: { to_table: :users }
      t.timestamps
      
      t.index [:user_id, :target_id], unique: true
    end
    
    add_check_constraint :user_follows, 'user_id != target_id', name: 'user_follows_no_self_follow'
  end
end