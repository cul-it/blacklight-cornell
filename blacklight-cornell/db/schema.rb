# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_12_03_142805) do
  create_table "blacklight_cornell_requests_requests", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "bookmarks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "document_id"
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_type"
    t.string "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "erm_data", id: false, force: :cascade do |t|
    t.integer "id"
    t.string "Collection_Name", limit: 128
    t.string "Collection_ID", limit: 20
    t.string "Provider_name", limit: 128
    t.string "Provider_Code", limit: 128
    t.string "Database_Name", limit: 128
    t.string "Database_Code", limit: 64
    t.string "Database_Status", limit: 128
    t.string "Title_Name", limit: 128
    t.string "Title_ID", limit: 20
    t.string "Title_Status", limit: 128
    t.string "ISSN", limit: 128
    t.string "eISSN", limit: 128
    t.string "ISBN", limit: 128
    t.string "SSID", limit: 128
    t.string "Prevailing", limit: 64
    t.string "License_Name", limit: 256
    t.string "Origin", limit: 256
    t.string "License_ID", limit: 64
    t.string "Type", limit: 256
    t.string "Vendor_License_URL", limit: 256
    t.string "Vendor_License_URL_Visible_In_Public_Display", limit: 16
    t.date "Vendor_License_URL_Date_Accessed"
    t.string "Second_Vendor_License_URL", limit: 256
    t.string "Local_License_URL", limit: 256
    t.string "Local_License_URL_Visible_In_Public_Display", limit: 16
    t.string "Second_Local_License_URL", limit: 256
    t.string "Physical_Location", limit: 256
    t.string "Status", limit: 128
    t.string "Reviewer", limit: 256
    t.text "Reviewer_Note"
    t.string "License_Replaced_By", limit: 256
    t.string "License_Replaces", limit: 256
    t.date "Execution_Date"
    t.date "Start_Date"
    t.date "End_Date"
    t.string "Advance_Notice_in_Days", limit: 64
    t.text "License_Note"
    t.date "Date_Created"
    t.date "Last_Updated"
    t.text "Template_Note"
    t.string "Authorized_Users", limit: 256
    t.text "Authorized_Users_Note"
    t.string "Concurrent_Users", limit: 64
    t.text "Concurrent_Users_Note"
    t.string "Fair_Use_Clause_Indicator", limit: 256
    t.string "Database_Protection_Override_Clause_Indicator", limit: 16
    t.string "All_Rights_Reserved_Indicator", limit: 16
    t.string "Citation_Requirement_Detail", limit: 256
    t.string "Digitally_Copy", limit: 256
    t.string "Digitally_Copy_Note", limit: 256
    t.string "Print_Copy", limit: 256
    t.string "Print_Copy_Note", limit: 256
    t.string "Scholarly_Sharing", limit: 128
    t.string "Scholarly_Sharing_Note", limit: 256
    t.string "Distance_Learning", limit: 128
    t.string "Distance_Learning_Note", limit: 256
    t.string "ILL_General", limit: 256
    t.string "ILL_Secure_Electronic", limit: 256
    t.string "ILL_Electronic_email", limit: 256
    t.string "ILL_Record_Keeping", limit: 128
    t.text "ILL_Record_Keeping_Note"
    t.string "Course_Reserve", limit: 128
    t.string "Course_Reserve_Note", limit: 256
    t.string "Electronic_Link", limit: 128
    t.string "Electronic_Link_Note", limit: 256
    t.string "Course_Pack_Print", limit: 128
    t.string "Course_Pack_Electronic", limit: 128
    t.string "Course_Pack_Note", limit: 256
    t.string "Remote_Access", limit: 128
    t.string "Remote_Access_Note", limit: 256
    t.string "Other_Use_Restrictions_Staff_Note", limit: 256
    t.string "Other_Use_Restrictions_Public_Note", limit: 256
    t.string "Perpetual_Access_Right", limit: 128
    t.text "Perpetual_Access_Note"
    t.string "Perpetual_Access_Holdings", limit: 256
    t.string "Licensee_Termination_Right", limit: 128
    t.string "Licensee_Termination_Condition", limit: 128
    t.string "Licensee_Termination_Note", limit: 256
    t.string "Licensee_Notice_Period_For_Termination_Number", limit: 128
    t.string "Licensee_Notice_Period_For_Termination_Unit", limit: 128
    t.string "Licensor_Termination_Right", limit: 128
    t.string "Licensor_Termination_Condition", limit: 128
    t.string "Licensor_Termination_Note", limit: 256
    t.string "Licensor_Notice_Period_For_Termination_Number", limit: 128
    t.string "Licensor_Notice_Period_For_Termination_Unit", limit: 256
    t.string "Termination_Right_Note", limit: 256
    t.string "Termination_Requirements", limit: 256
    t.string "Termination_Requirements_Note", limit: 256
    t.string "Terms_Note", limit: 256
    t.string "Local_Use_Terms_Note", limit: 256
    t.string "Governing_Law", limit: 256
    t.string "Governing_Jurisdiction", limit: 256
    t.string "Applicable_Copyright_Law", limit: 256
    t.string "Cure_Period_For_Breach_Number", limit: 256
    t.string "Cure_Period_For_Breach_Unit", limit: 256
    t.string "Renewal_Type", limit: 128
    t.string "Non_Renewal_Notice_Period_Number", limit: 128
    t.string "Non_Renewal_Notice_Period_Unit", limit: 128
    t.string "Archiving_Right", limit: 128
    t.string "Archiving_Format", limit: 256
    t.text "Archiving_Note"
    t.string "Pre_Print_Archive_Allowed", limit: 128
    t.string "Pre_Print_Archive_Conditions", limit: 256
    t.string "Pre_Print_Archive_Restrictions_Number", limit: 128
    t.string "Pre_Print_Archive_Restrictions_Unit", limit: 128
    t.string "Pre_Print_Archive_Note", limit: 256
    t.string "Post_Print_Archive_Allowed", limit: 128
    t.string "Post_Print_Archive_Conditions", limit: 256
    t.string "Post_Print_Archive_Restrictions_Number", limit: 128
    t.string "Post_Print_Archive_Restrictions_Unit", limit: 128
    t.string "Post_Print_Archive_Note", limit: 256
    t.string "Incorporation_Of_Images_Figures_And_Tables_Right", limit: 256
    t.text "Incorporation_Of_Images_Figures_And_Tables_Note"
    t.string "Public_Performance_Right", limit: 256
    t.text "Public_Performance_Note"
    t.string "Training_Materials_Right", limit: 256
    t.text "Training_Materials_Note"
  end

  create_table "locations", force: :cascade do |t|
    t.integer "voyager_id"
    t.string "code"
    t.string "display_name"
    t.string "hours_page"
    t.boolean "rmc_aeon"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["code"], name: "index_locations_on_code", unique: true
    t.index ["voyager_id"], name: "index_locations_on_voyager_id", unique: true
  end

  create_table "searches", force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_type"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "term_of_uses", id: false, force: :cascade do |t|
    t.string "id", limit: 128
    t.string "title_id", limit: 128
    t.string "package_id", limit: 256
    t.string "record_title", limit: 512
    t.string "record_title_label", limit: 512
    t.string "authorised_users_label", limit: 128
    t.string "authorised_users_value", limit: 512
    t.string "authorised_users_internal", limit: 12
    t.integer "authorised_users_weight", limit: 4
    t.string "walk-in_access_label", limit: 128
    t.string "walk-in_access_value", limit: 5
    t.string "walk-in_access_internal", limit: 12
    t.integer "walk-in_access_weight", limit: 4
    t.text "walk-in_access_description"
    t.string "electronic_ill_label", limit: 128
    t.string "electronic_ill_value", limit: 128
    t.string "electronic_ill_internal", limit: 12
    t.integer "electronic_ill_weight", limit: 4
    t.text "electronic_ill_description"
    t.string "secure_electronic_ill_label", limit: 128
    t.string "secure_electronic_ill_value", limit: 128
    t.string "secure_electronic_ill_internal", limit: 12
    t.integer "secure_electronic_ill_weight", limit: 4
    t.text "secure_electronic_ill_description"
    t.string "sharing_for_scholarly_use_label", limit: 128
    t.string "sharing_for_scholarly_use_value", limit: 128
    t.string "sharing_for_scholarly_use_internal", limit: 12
    t.integer "sharing_for_scholarly_use_weight", limit: 4
    t.text "sharing_for_scholarly_use_description"
    t.string "cure_period_for_breach_unit_label", limit: 128
    t.string "cure_period_for_breach_unit_value", limit: 128
    t.string "cure_period_for_breach_unit_internal", limit: 12
    t.integer "cure_period_for_breach_unit_weight", limit: 4
    t.text "cure_period_for_breach_unit_description"
    t.string "ill_record_keeping_label", limit: 128
    t.string "ill_record_keeping_value", limit: 128
    t.string "ill_record_keeping_internal", limit: 12
    t.integer "ill_record_keeping_weight", limit: 4
    t.text "ill_record_keeping_description"
    t.string "electronic_link_label", limit: 128
    t.string "electronic_link_value", limit: 128
    t.string "electronic_link_internal", limit: 12
    t.integer "electronic_link_weight", limit: 4
    t.text "electronic_link_description"
    t.string "governing_law_label", limit: 128
    t.string "governing_law_value", limit: 128
    t.string "governing_law_internal", limit: 12
    t.integer "governing_law_weight", limit: 4
    t.text "governing_law_description"
    t.string "general_permissions_label", limit: 128
    t.text "general_permissions_value"
    t.string "general_permissions_internal", limit: 12
    t.integer "general_permissions_weight", limit: 4
    t.text "general_permissions_description"
    t.string "general_restrictions_label", limit: 128
    t.text "general_restrictions_value"
    t.string "general_restrictions_internal", limit: 12
    t.integer "general_restrictions_weight", limit: 4
    t.text "general_restrictions_description"
    t.string "cure_period_for_breach_label", limit: 128
    t.integer "cure_period_for_breach_value", limit: 4
    t.string "cure_period_for_breach_internal", limit: 12
    t.integer "cure_period_for_breach_weight", limit: 4
    t.text "cure_period_for_breach_description"
    t.string "course_reserve_label", limit: 128
    t.string "course_reserve_value", limit: 128
    t.string "course_reserve_internal", limit: 12
    t.integer "course_reserve_weight", limit: 4
    t.text "course_reserve_description"
    t.string "ill_general_label", limit: 128
    t.string "ill_general_value", limit: 128
    t.string "ill_general_internal", limit: 12
    t.integer "ill_general_weight", limit: 4
    t.text "ill_general_description"
    t.string "fair_use_clause_indicator_label", limit: 128
    t.string "fair_use_clause_indicator_value", limit: 128
    t.string "fair_use_clause_indicator_internal", limit: 12
    t.integer "fair_use_clause_indicator_weight", limit: 4
    t.text "fair_use_clause_indicator_description"
    t.string "packageID", limit: 128
    t.string "packageName", limit: 256
    t.string "packageUrl", limit: 512
    t.string "package_providerID", limit: 512
    t.string "package_providerName", limit: 128
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "guest", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
