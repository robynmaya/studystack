class CreateStreamViewers < ActiveRecord::Migration[8.0]
  def change
    create_table :stream_viewers do |t|
      t.references :live_stream, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :joined_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :left_at

      t.timestamps
    end
    
    add_index :stream_viewers, [:live_stream_id, :user_id], unique: true
  end
end
