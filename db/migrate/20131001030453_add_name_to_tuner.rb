class AddNameToTuner < ActiveRecord::Migration
  def change
    add_column :tuners, :name, :string
  end
end
