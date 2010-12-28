class CreateTimeIntervals < ActiveRecord::Migration
	def self.up
		create_table :time_intervals do |t|
			t.integer :interval
			t.string :unit, :limit => 10
			t.string :description, :limit => 20
		end
	end

	def self.down
		drop_table :time_intervals
	end
end
