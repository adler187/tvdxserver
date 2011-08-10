class AddPositionToTuners < ActiveRecord::Migration
  def self.up
    add_column :tuners, :position, :integer
    
    # set the positions to the order they were created,
    Tuner.all.each_with_index do |tuner, index|
      tuner.position = index
      tuner.save
    end  
  end

  def self.down
    remove_column :tuners, :position
  end
end
