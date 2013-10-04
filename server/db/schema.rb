# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131001030453) do

  create_table "logs", :force => true do |t|
    t.integer  "signal_strength", :limit => 4
    t.integer  "signal_to_noise", :limit => 4
    t.integer  "signal_quality",  :limit => 4
    t.integer  "station_id"
    t.integer  "tuner_id"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "logs", ["created_at"], :name => "index_logs_on_created_at"

  create_table "recent_logs", :force => true do |t|
    t.integer  "signal_strength", :limit => 4
    t.integer  "signal_to_noise", :limit => 4
    t.integer  "signal_quality",  :limit => 4
    t.integer  "station_id"
    t.integer  "tuner_id"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "recent_logs", ["station_id", "tuner_id"], :name => "index_recent_logs_on_station_id_and_tuner_id", :unique => true

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

  add_index "stations", ["tsid", "display", "rf"], :name => "index_stations_on_tsid_and_display_and_rf", :unique => true

  create_table "time_intervals", :force => true do |t|
    t.integer "interval"
    t.string  "unit",     :limit => 10
    t.integer "position"
  end

  create_table "tuner_infos", :force => true do |t|
    t.integer  "tuner_id"
    t.text     "info"
    t.datetime "created_at"
    t.decimal  "lattitude",  :precision => 6, :scale => 4
    t.decimal  "longitude",  :precision => 6, :scale => 4
  end

  create_table "tuners", :force => true do |t|
    t.string  "tuner_id",     :limit => 10
    t.integer "tuner_number", :limit => 1
    t.integer "position"
    t.string  "name"
  end

end
