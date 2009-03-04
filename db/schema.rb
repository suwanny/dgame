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

ActiveRecord::Schema.define(:version => 20090302013857) do

  create_table "events", :force => true do |t|
    t.integer  "user_id"
    t.string   "action"
    t.string   "result"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :default => "", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "states", :force => true do |t|
    t.string   "state_name"
    t.integer  "user_id"
    t.integer  "soldiers"
    t.integer  "alliance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "hashed_password"
    t.string   "salt"
    t.string   "email"
    t.integer  "turns"
    t.integer  "alliance"
    t.integer  "total_soldiers",         :default => 0
    t.integer  "total_zones",            :default => 0
    t.integer  "score"
    t.datetime "last_time_turns_commit"
    t.datetime "last_time_login"
    t.text     "public_info"
    t.float    "viewport_x"
    t.float    "viewport_y"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "color_r"
    t.integer  "color_g"
    t.integer  "color_b"
    t.integer  "jammingcount"
  end

  create_table "zones", :force => true do |t|
    t.integer  "x"
    t.integer  "y"
    t.integer  "user_id"
    t.integer  "soldiers"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "artillery"
    t.boolean  "jamming"
    t.boolean  "bunker"
    t.integer  "score"
  end

end
