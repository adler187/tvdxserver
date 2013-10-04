class AddLocationToTunerInfos < ActiveRecord::Migration
  def change
    add_column :tuner_infos, :lattitude, :decimal, :precision => 6, :scale => 4
    add_column :tuner_infos, :longitude, :decimal, :precision => 6, :scale => 4
  end
end
