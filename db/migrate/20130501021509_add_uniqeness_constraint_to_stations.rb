class AddUniqenessConstraintToStations < ActiveRecord::Migration
  def change
    add_index :stations, [:tsid, :display, :rf], :unique => true
  end
end
