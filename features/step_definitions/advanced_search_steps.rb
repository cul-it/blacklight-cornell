When("I select {string} from the row logic radio before line {int}") do |string, int|
  row_offset = int
  # expect(find(:element, "input", type: "radio", value: "#{string.upcase}")).to have_text(string)
  # elt = page.find("div.input_row:nth-child(#{row_offset})")
  # what_is elt
  within("div.input_row:nth-child(#{row_offset}) > fieldset > div.adv-search-control") do 
    find_field(string, :disabled => :all).set(true)
  end
end

When("I select {string} from the term logic drop-down on line {int}") do |string, int|
  if int == 1
    id = "op_row"
  else
    id = "op_row#{int}"
  end
  page.find_by_id(id).select( "#{string}")
end

When("I select {string} from the fields drop-down on line {int}") do |string, int|
  if int == 1
    id = "search_field_advanced"
  else
    id = "search_field_advanced#{int}"
  end
  page.find_by_id(id).select( "#{string}")
end

# html.js body.advanced_search.advanced_search-index div#maincontent.main-content div#main-container.container div.row div.col-sm-12 div.card.card-body.card-well form.advanced div.query_zone div.input_row fieldset div.boolean_row.radio.adv-search-control div.form-check.form-check-inline label input
# div.input_row:nth-child(3) > fieldset:nth-child(1) > div:nth-child(2) > div:nth-child(1) > label:nth-child(1) > input:nth-child(1)
