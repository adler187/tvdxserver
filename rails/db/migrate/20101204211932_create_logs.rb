class CreateLogs < ActiveRecord::Migration
	def self.up
		create_table :logs do |t|
			t.integer :signal_strength, :limit => 4
			t.integer :signal_to_noise, :limit => 4
			t.integer :signal_quality, :limit => 4
			t.references :station
			t.references :tuner
			t.timestamps
		end
	end

	def self.down
		drop_table :logs
	end
end
