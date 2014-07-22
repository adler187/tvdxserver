class AddScanIntervalToTuner < ActiveRecord::Migration
  def change
    add_column :tuners, :scan_interval, :integer, default: 10
  end
end
