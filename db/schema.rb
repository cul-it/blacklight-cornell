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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150507152505) do

  create_table "blacklight_cornell_requests_circ_policy_locs", force: :cascade do |t|
    t.integer "CIRC_GROUP_ID",   limit: 4
    t.integer "LOCATION_ID",     limit: 4
    t.string  "PICKUP_LOCATION", limit: 1
  end

  add_index "blacklight_cornell_requests_circ_policy_locs", ["CIRC_GROUP_ID", "PICKUP_LOCATION"], name: "key_cgi_pl"
  add_index "blacklight_cornell_requests_circ_policy_locs", ["LOCATION_ID"], name: "key_location_id"

<<<<<<< HEAD
  create_table "blacklight_cornell_requests_requests", force: :cascade do |t|
=======
  create_table "blacklight_cornell_requests_requests", force: true do |t|
>>>>>>> origin/authorities
    t.datetime "created_at"
    t.datetime "updated_at"
  end

<<<<<<< HEAD
  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,   null: false
    t.string   "document_id",   limit: 255
    t.string   "title",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type",     limit: 255
    t.string   "document_type", limit: 255
=======
  create_table "bookmarks", force: true do |t|
    t.integer  "user_id",     null: false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
>>>>>>> origin/authorities
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id", using: :btree

  create_table "erm_data", id: false, force: :cascade do |t|
    t.integer "id",                                               limit: 4
    t.string  "Collection_Name",                                  limit: 128
    t.string  "Collection_ID",                                    limit: 20
    t.string  "Provider_name",                                    limit: 128
    t.string  "Provider_Code",                                    limit: 128
    t.string  "Database_Name",                                    limit: 128
    t.string  "Database_Code",                                    limit: 64
    t.string  "Database_Status",                                  limit: 128
    t.string  "Title_Name",                                       limit: 128
    t.string  "Title_ID",                                         limit: 20
    t.string  "Title_Status",                                     limit: 128
    t.string  "ISSN",                                             limit: 128
    t.string  "eISSN",                                            limit: 128
    t.string  "ISBN",                                             limit: 128
    t.string  "SSID",                                             limit: 128
    t.string  "Prevailing",                                       limit: 64
    t.string  "License_Name",                                     limit: 256
    t.string  "Origin",                                           limit: 256
    t.string  "License_ID",                                       limit: 64
    t.string  "Type",                                             limit: 256
    t.string  "Vendor_License_URL",                               limit: 256
    t.string  "Vendor_License_URL_Visible_In_Public_Display",     limit: 16
    t.date    "Vendor_License_URL_Date_Accessed"
    t.string  "Second_Vendor_License_URL",                        limit: 256
    t.string  "Local_License_URL",                                limit: 256
    t.string  "Local_License_URL_Visible_In_Public_Display",      limit: 16
    t.string  "Second_Local_License_URL",                         limit: 256
    t.string  "Physical_Location",                                limit: 256
    t.string  "Status",                                           limit: 128
    t.string  "Reviewer",                                         limit: 256
    t.text    "Reviewer_Note",                                    limit: 65535
    t.string  "License_Replaced_By",                              limit: 256
    t.string  "License_Replaces",                                 limit: 256
    t.date    "Execution_Date"
    t.date    "Start_Date"
    t.date    "End_Date"
    t.string  "Advance_Notice_in_Days",                           limit: 64
    t.text    "License_Note",                                     limit: 65535
    t.date    "Date_Created"
    t.date    "Last_Updated"
    t.text    "Template_Note",                                    limit: 65535
    t.string  "Authorized_Users",                                 limit: 256
    t.text    "Authorized_Users_Note",                            limit: 65535
    t.string  "Concurrent_Users",                                 limit: 64
    t.text    "Concurrent_Users_Note",                            limit: 65535
    t.string  "Fair_Use_Clause_Indicator",                        limit: 256
    t.string  "Database_Protection_Override_Clause_Indicator",    limit: 16
    t.string  "All_Rights_Reserved_Indicator",                    limit: 16
    t.string  "Citation_Requirement_Detail",                      limit: 256
    t.string  "Digitally_Copy",                                   limit: 256
    t.string  "Digitally_Copy_Note",                              limit: 256
    t.string  "Print_Copy",                                       limit: 256
    t.string  "Print_Copy_Note",                                  limit: 256
    t.string  "Scholarly_Sharing",                                limit: 128
    t.string  "Scholarly_Sharing_Note",                           limit: 256
    t.string  "Distance_Learning",                                limit: 128
    t.string  "Distance_Learning_Note",                           limit: 256
    t.string  "ILL_General",                                      limit: 256
    t.string  "ILL_Secure_Electronic",                            limit: 256
    t.string  "ILL_Electronic_email",                             limit: 256
    t.string  "ILL_Record_Keeping",                               limit: 128
    t.text    "ILL_Record_Keeping_Note",                          limit: 65535
    t.string  "Course_Reserve",                                   limit: 128
    t.string  "Course_Reserve_Note",                              limit: 256
    t.string  "Electronic_Link",                                  limit: 128
    t.string  "Electronic_Link_Note",                             limit: 256
    t.string  "Course_Pack_Print",                                limit: 128
    t.string  "Course_Pack_Electronic",                           limit: 128
    t.string  "Course_Pack_Note",                                 limit: 256
    t.string  "Remote_Access",                                    limit: 128
    t.string  "Remote_Access_Note",                               limit: 256
    t.string  "Other_Use_Restrictions_Staff_Note",                limit: 256
    t.string  "Other_Use_Restrictions_Public_Note",               limit: 256
    t.string  "Perpetual_Access_Right",                           limit: 128
    t.text    "Perpetual_Access_Note",                            limit: 65535
    t.string  "Perpetual_Access_Holdings",                        limit: 256
    t.string  "Licensee_Termination_Right",                       limit: 128
    t.string  "Licensee_Termination_Condition",                   limit: 128
    t.string  "Licensee_Termination_Note",                        limit: 256
    t.string  "Licensee_Notice_Period_For_Termination_Number",    limit: 128
    t.string  "Licensee_Notice_Period_For_Termination_Unit",      limit: 128
    t.string  "Licensor_Termination_Right",                       limit: 128
    t.string  "Licensor_Termination_Condition",                   limit: 128
    t.string  "Licensor_Termination_Note",                        limit: 256
    t.string  "Licensor_Notice_Period_For_Termination_Number",    limit: 128
    t.string  "Licensor_Notice_Period_For_Termination_Unit",      limit: 256
    t.string  "Termination_Right_Note",                           limit: 256
    t.string  "Termination_Requirements",                         limit: 256
    t.string  "Termination_Requirements_Note",                    limit: 256
    t.string  "Terms_Note",                                       limit: 256
    t.string  "Local_Use_Terms_Note",                             limit: 256
    t.string  "Governing_Law",                                    limit: 256
    t.string  "Governing_Jurisdiction",                           limit: 256
    t.string  "Applicable_Copyright_Law",                         limit: 256
    t.string  "Cure_Period_For_Breach_Number",                    limit: 256
    t.string  "Cure_Period_For_Breach_Unit",                      limit: 256
    t.string  "Renewal_Type",                                     limit: 128
    t.string  "Non_Renewal_Notice_Period_Number",                 limit: 128
    t.string  "Non_Renewal_Notice_Period_Unit",                   limit: 128
    t.string  "Archiving_Right",                                  limit: 128
    t.string  "Archiving_Format",                                 limit: 256
    t.text    "Archiving_Note",                                   limit: 65535
    t.string  "Pre_Print_Archive_Allowed",                        limit: 128
    t.string  "Pre_Print_Archive_Conditions",                     limit: 256
    t.string  "Pre_Print_Archive_Restrictions_Number",            limit: 128
    t.string  "Pre_Print_Archive_Restrictions_Unit",              limit: 128
    t.string  "Pre_Print_Archive_Note",                           limit: 256
    t.string  "Post_Print_Archive_Allowed",                       limit: 128
    t.string  "Post_Print_Archive_Conditions",                    limit: 256
    t.string  "Post_Print_Archive_Restrictions_Number",           limit: 128
    t.string  "Post_Print_Archive_Restrictions_Unit",             limit: 128
    t.string  "Post_Print_Archive_Note",                          limit: 256
    t.string  "Incorporation_Of_Images_Figures_And_Tables_Right", limit: 256
    t.text    "Incorporation_Of_Images_Figures_And_Tables_Note",  limit: 65535
    t.string  "Public_Performance_Right",                         limit: 256
    t.text    "Public_Performance_Note",                          limit: 65535
    t.string  "Training_Materials_Right",                         limit: 256
<<<<<<< HEAD
    t.text    "Training_Materials_Note",                          limit: 65535
  end

  create_table "searches", force: :cascade do |t|
    t.text     "query_params", limit: 65535
    t.integer  "user_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type",    limit: 255
=======
    t.text    "Training_Materials_Note"
  end

  create_table "searches", force: true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
>>>>>>> origin/authorities
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

<<<<<<< HEAD
  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,        null: false
    t.text     "data",       limit: 4294967295
=======
  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
>>>>>>> origin/authorities
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
<<<<<<< HEAD
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "guest",                  limit: 1,   default: false
=======
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "guest",                  default: false
>>>>>>> origin/authorities
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
