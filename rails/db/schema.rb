# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101204211932) do

  create_table "logs", :force => true do |t|
    t.integer  "signal_strength", :limit => 4
    t.integer  "signal_to_noise", :limit => 4
    t.integer  "signal_quality",  :limit => 4
    t.integer  "station_id"
    t.integer  "tuner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stations", :force => true do |t|
    t.string  "tsid",            :limit => 6
    t.string  "callsign",        :limit => 10
    t.string  "parent_callsign", :limit => 7
    t.integer "rf",              :limit => 4
    t.integer "display",         :limit => 4
    t.decimal "latitude",                      :precision => 6, :scale => 4
    t.decimal "longitude",                     :precision => 6, :scale => 4
    t.decimal "distance",                      :precision => 5, :scale => 1
  end

  create_table "tuner_infos", :force => true do |t|
    t.integer  "tuner_id"
    t.text     "info"
    t.datetime "created_at"
  end

  create_table "tuners", :force => true do |t|
    t.string  "tuner_id",     :limit => 10
    t.integer "tuner_number", :limit => 1
  end

end