class CreateTermOfUses < ActiveRecord::Migration[5.2]
def up
create_table "term_of_uses", id: false, force: true do |t|
  t.string  "id",                                                 limit: 128 
  t.string   "title_id",                                          limit: 128
  t.string   "package_id",                                        limit: 256
  t.string   "record_title",                                      limit: 512
  t.string   "record_title_label",                                limit: 512
  t.string   "authorised_users_label",                            limit: 128
  t.string   "authorised_users_value",                            limit: 512
  t.string   "authorised_users_internal",                         limit: 12
  t.integer  "authorised_users_weight",                           limit: 4
  t.string   "walk-in_access_label",                              limit: 128
  t.string   "walk-in_access_value",                              limit: 5
  t.string   "walk-in_access_internal",                           limit: 12
  t.integer  "walk-in_access_weight",                             limit: 4
  t.text     "walk-in_access_description"
  t.string   "electronic_ill_label",                              limit: 128
  t.string   "electronic_ill_value",                              limit: 128
  t.string   "electronic_ill_internal",                           limit: 12
  t.integer  "electronic_ill_weight",                             limit: 4
  t.text     "electronic_ill_description"
  t.string   "secure_electronic_ill_label",                       limit: 128
  t.string   "secure_electronic_ill_value",                       limit: 128
  t.string   "secure_electronic_ill_internal",                    limit: 12
  t.integer  "secure_electronic_ill_weight",                      limit: 4
  t.text     "secure_electronic_ill_description"
  t.string   "sharing_for_scholarly_use_label",                   limit: 128
  t.string   "sharing_for_scholarly_use_value",                   limit: 128
  t.string   "sharing_for_scholarly_use_internal",                limit: 12
  t.integer  "sharing_for_scholarly_use_weight",                  limit: 4
  t.text     "sharing_for_scholarly_use_description"
  t.string   "cure_period_for_breach_unit_label",                 limit: 128
  t.string   "cure_period_for_breach_unit_value",                 limit: 128
  t.string   "cure_period_for_breach_unit_internal",              limit: 12
  t.integer  "cure_period_for_breach_unit_weight",                limit: 4
  t.text     "cure_period_for_breach_unit_description"
  t.string   "ill_record_keeping_label",                          limit: 128
  t.string   "ill_record_keeping_value",                          limit: 128
  t.string   "ill_record_keeping_internal",                       limit: 12
  t.integer  "ill_record_keeping_weight",                         limit: 4
  t.text     "ill_record_keeping_description"
  t.string   "electronic_link_label",                             limit: 128
  t.string   "electronic_link_value",                             limit: 128
  t.string   "electronic_link_internal",                          limit: 12
  t.integer  "electronic_link_weight",                            limit: 4
  t.text     "electronic_link_description"
  t.string   "governing_law_label",                               limit: 128
  t.string   "governing_law_value",                               limit: 128
  t.string   "governing_law_internal",                            limit: 12
  t.integer  "governing_law_weight",                              limit: 4
  t.text     "governing_law_description"
  t.string   "general_permissions_label",                         limit: 128
  t.text     "general_permissions_value"
  t.string   "general_permissions_internal",                       limit: 12
  t.integer  "general_permissions_weight",                         limit: 4
  t.text     "general_permissions_description"
  t.string   "general_restrictions_label",                        limit: 128
  t.text     "general_restrictions_value"
  t.string   "general_restrictions_internal",                     limit: 12
  t.integer  "general_restrictions_weight",                       limit: 4
  t.text     "general_restrictions_description"
  t.string   "cure_period_for_breach_label",                      limit: 128
  t.integer  "cure_period_for_breach_value",                      limit: 4
  t.string   "cure_period_for_breach_internal",                   limit: 12
  t.integer  "cure_period_for_breach_weight",                     limit: 4
  t.text     "cure_period_for_breach_description"
  t.string   "course_reserve_label",                              limit: 128
  t.string   "course_reserve_value",                              limit: 128
  t.string   "course_reserve_internal",                           limit: 12
  t.integer  "course_reserve_weight",                             limit: 4
  t.text     "course_reserve_description"
  t.string   "ill_general_label",                                 limit: 128
  t.string   "ill_general_value",                                 limit: 128
  t.string   "ill_general_internal",                              limit: 12
  t.integer  "ill_general_weight",                                limit: 4
  t.text     "ill_general_description"
  t.string   "fair_use_clause_indicator_label",                   limit: 128
  t.string   "fair_use_clause_indicator_value",                   limit: 128             
  t.string   "fair_use_clause_indicator_internal",                limit: 12             
  t.integer  "fair_use_clause_indicator_weight",                  limit: 4
  t.text     "fair_use_clause_indicator_description"  
  t.string   "packageID",                                         limit: 128
  t.string   "packageName",                                       limit: 256
  t.string   "packageUrl",                                        limit: 512
  t.string   "package_providerID",                                limit: 512
  t.string   "package_providerName",                              limit: 128                   
 end
end 
 
def down
end

end
