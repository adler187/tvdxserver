class AddIndexToLog < ActiveRecord::Migration
  def self.up
	  add_index :logs, :created_at
  end

  def self.down
	  drop_index :logs, :created_at
  end
end
