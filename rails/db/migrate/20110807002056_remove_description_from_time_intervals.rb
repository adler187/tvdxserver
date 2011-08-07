class RemoveDescriptionFromTimeIntervals < ActiveRecord::Migration
  def self.up
    remove_column :time_intervals, :description
  end

  def self.down
    add_column :time_intervals, :description, :string
  end
end
