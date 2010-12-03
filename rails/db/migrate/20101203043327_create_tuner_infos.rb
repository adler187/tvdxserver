class CreateTunerInfos < ActiveRecord::Migration
  def self.up
    create_table :tuner_infos do |t|
      t.references :tuner
	  t.text :info
	  t.datetime :created_at
    end
  end

  def self.down
    drop_table :tuner_infos
  end
end
