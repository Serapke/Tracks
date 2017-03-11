class CreatePlaces < ActiveRecord::Migration[5.0]
  def change
    create_table :places do |t|
      t.column :top_left, :point
      t.column :top_right, :point
      t.column :bottom_right, :point
      t.column :bottom_left, :point

      t.timestamps
    end
  end
end