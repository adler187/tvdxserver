class AddPositionToTimeIntervals < ActiveRecord::Migration
  def self.up
    add_column :time_intervals, :position, :integer
    
    # set the positions to the order they were created,
    # except the 'All' entry, which is special and should be last
    TimeInterval.all.each_with_index do |interval, index|
      interval.position = interval.all_interval? ? TimeInterval.count : index
      interval.save
    end   
  end

  def self.down
    remove_column :time_intervals, :position
  end
end
