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

ActiveRecord::Schema.define(:version => 20131217154546) do

  create_table "ERM_DATA", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "Collection_Name",                                 :limit => 128
    t.string  "Collection_ID",                                   :limit => 20
    t.string  "Provider_name",                                   :limit => 128
    t.string  "Provider_Code",                                   :limit => 128
    t.string  "Database_Name",                                   :limit => 128
    t.string  "Database_Code",                                   :limit => 64
    t.string  "Database_Status",                                 :limit => 128
    t.string  "Title_Name",                                      :limit => 128
    t.string  "Title_ID",                                        :limit => 20
    t.string  "Title_Status",                                    :limit => 128
    t.string  "ISSN",                                            :limit => 128
    t.string  "eISSN",                                           :limit => 128
    t.string  "ISBN",                                            :limit => 128
    t.string  "SSID",                                            :limit => 128
    t.string  "Prevailing",                                      :limit => 64
    t.string  "License_Name",                                    :limit => 256
    t.string  "Origin",                                          :limit => 256
    t.string  "License_ID",                                      :limit => 64
    t.string  "Type",                                            :limit => 256
    t.string  "Vendor_License_URL",                              :limit => 256
    t.date    "Vendor_License_URL_Date_Accessed"
    t.string  "Local_License_URL",                               :limit => 256
    t.string  "Physical_Location",                               :limit => 256
    t.string  "Status",                                          :limit => 128
    t.string  "Reviewer",                                        :limit => 256
    t.text    "Reviewer_Note"
    t.string  "License_Replaced_By",                             :limit => 256
    t.string  "License_Replaces",                                :limit => 256
    t.date    "Execution_Date"
    t.date    "Start_Date"
    t.date    "End_Date"
    t.string  "Advance_Notice_in_Days",                          :limit => 64
    t.text    "License_Note"
    t.date    "Date_Created"
    t.date    "Last_Updated"
    t.text    "Template_Note"
    t.string  "Authorized_Users",                                :limit => 256
    t.text    "Authorized_Users_Note"
    t.string  "Concurrent_Users",                                :limit => 64
    t.text    "Concurrent_Users_Note"
    t.string  "ILL_General",                                     :limit => 256
    t.string  "ILL_Secure_Electronic",                           :limit => 256
    t.string  "ILL_Electronic_email",                            :limit => 256
    t.string  "ILL_Record_Keeping",                              :limit => 128
    t.text    "ILL_Record_Keeping_Note"
    t.string  "Perpetual_Access_Right",                          :limit => 128
    t.text    "Perpetual_Access_Note"
    t.string  "Perpetual_Access_Holdings",                       :limit => 256
    t.string  "Archiving_Right",                                 :limit => 128
    t.string  "Archiving_Format",                                :limit => 256
    t.text    "Archiving_Note"
    t.string  "Incorporation_of_Image_Figures_and_Tables_Right", :limit => 256
    t.text    "Incorporation_of_Image_Figures_and_Tables_Note"
    t.string  "Public_Performance_Right",                        :limit => 256
    t.text    "Public_Performance_Note"
    t.string  "Training_Materials_Right",                        :limit => 256
    t.text    "Training_Materials_Note"
  end

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

  create_table "models", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "models", ["email"], :name => "index_models_on_email", :unique => true
  add_index "models", ["reset_password_token"], :name => "index_models_on_reset_password_token", :unique => true

  create_table "searches", :force => true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "user_type"
  end

  add_index "searches", ["user_id"], :name => "index_searches_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "guest",                  :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
