class CreateSongs < ActiveRecord::Migration[5.0]
  def change
    create_table :songs do |t|
      t.integer :spotify_id
      t.column :user_id, :integer

      t.timestamps
    end
    add_index :songs, :user_id
  end
end
