class CreateLiveStreams < ActiveRecord::Migration[8.0]
  def change
    create_table :live_streams do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'scheduled'
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :viewer_count, default: 0

      t.timestamps
    end
    
    add_index :live_streams, :status
    add_index :live_streams, :started_at
  end
end
