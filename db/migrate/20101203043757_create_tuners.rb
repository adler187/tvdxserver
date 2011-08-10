class CreateTuners < ActiveRecord::Migration
  def self.up
    create_table :tuners do |t|
      t.string :tuner_id, :limit => 10
      t.integer :tuner_number, :limit => 1
    end
  end

  def self.down
    drop_table :tuners
  end
end
