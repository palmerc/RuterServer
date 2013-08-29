class CreateStops < ActiveRecord::Migration
  def change
    create_table :stops do |t|
      t.integer :stop_id
      t.string :name
      t.float :latitude
      t.float :longitude
      t.float :northing
      t.float :easting
      t.integer :fare_zone

      t.timestamps
    end
  end
end
