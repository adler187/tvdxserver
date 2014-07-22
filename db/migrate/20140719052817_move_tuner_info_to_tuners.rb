class TunerInfo < ActiveRecord::Base
  belongs_to :tuner
end

class MoveTunerInfoToTuners < ActiveRecord::Migration
  def up
    add_column :tuners, :info, :text
    add_column :tuners, :latitude, :decimal, :precision => 6, :scale => 4
    add_column :tuners, :longitude, :decimal, :precision => 6, :scale => 4
    add_column :tuners, :created_at, :datetime
    add_column :tuners, :updated_at, :datetime
    
    Tuner.all.each do |tuner|
      tuner_info = TunerInfo.where(tuner_id: tuner.id)[-1]
      
      unless tuner_info.nil? 
        tuner.info = tuner_info.info
        tuner.latitude = tuner_info.lattitude
        tuner.longitude = tuner_info.longitude
        tuner.updated_at = tuner_info.created_at
        
        tuner.save!
      end
    end
    
    drop_table :tuner_infos
  end

  def down
    create_table "tuner_infos", :force => true do |t|
      t.integer  "tuner_id"
      t.text     "info"
      t.datetime "created_at"
      t.decimal  "lattitude",  :precision => 6, :scale => 4
      t.decimal  "longitude",  :precision => 6, :scale => 4
    end
    
    Tuner.all.each do |tuner|
      t = TunerInfo.new(tuner_id: tuner.id, info: tuner.info, created_at: tuner.updated_at, lattitude: tuner.latitude, longitude: tuner.longitude)
      t.save
    end
    
    remove_column :tuners, :info
    remove_column :tuners, :latitude
    remove_column :tuners, :longitude
    remove_column :tuners, :created_at
    remove_column :tuners, :updated_at
  end
end
