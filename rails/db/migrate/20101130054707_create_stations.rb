class CreateStations < ActiveRecord::Migration
  def self.up
    create_table :stations do |t|
      t.string :tsid, :limit => 6
      t.string :callsign, :limit => 10
      t.string :parent_callsign, :limit => 7
      t.integer :rf, :limit => 4
      t.integer :display, :limit => 4
      t.decimal :latitude, :precision => 6, :scale => 4
      t.decimal :longitude, :precision => 6, :scale => 4
      t.decimal :distance, :precision => 5, :scale => 1
    end
  end

  def self.down
    drop_table :stations
  end
end
