class CreateRecentLogs < ActiveRecord::Migration
  def up
   create_table :recent_logs do |t|
      t.integer :signal_strength, :limit => 4
      t.integer :signal_to_noise, :limit => 4
      t.integer :signal_quality, :limit => 4
      t.references :station
      t.references :tuner
      t.timestamps
    end
    
    add_index(:recent_logs, [:station_id, :tuner_id], :unique => true)
    
    Tuner.all.each do |tuner|
      Station.all.each do |station|
        log = Log.where(:tuner_id => tuner.id).where(:station_id => station.id).order("created_at DESC").first
        
        unless log.nil?
          r = RecentLog.new(log.attributes)
          r.save
        end
      end
    end
  end

  def down
    drop_table :recent_logs
  end
end
