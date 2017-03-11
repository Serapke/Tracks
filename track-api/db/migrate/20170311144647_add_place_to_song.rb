class AddPlaceToSong < ActiveRecord::Migration[5.0]
  def change
    add_reference :songs, :place, foreign_key: true
  end
end
