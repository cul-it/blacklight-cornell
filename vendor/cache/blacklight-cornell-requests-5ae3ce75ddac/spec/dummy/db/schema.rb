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

ActiveRecord::Schema.define(:version => 20141205183449) do

  create_table "blacklight_cornell_requests_circ_policy_locs", :force => true do |t|
    t.integer "CIRC_GROUP_ID"
    t.integer "LOCATION_ID"
    t.string  "PICKUP_LOCATION", :limit => 1
  end

  add_index "blacklight_cornell_requests_circ_policy_locs", ["CIRC_GROUP_ID", "PICKUP_LOCATION"], :name => "key_cgi_pl"
  add_index "blacklight_cornell_requests_circ_policy_locs", ["LOCATION_ID"], :name => "key_location_id"

  create_table "blacklight_cornell_requests_requests", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "bookmarks", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "user_type"
  end

  create_table "searches", :force => true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "user_type"
  end

  add_index "searches", ["user_id"], :name => "index_searches_on_user_id"

end
