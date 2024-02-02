When("I select {string} from the row logic radio before line {int}") do |string, int|
  row_offset = int
  # expect(find(:element, "input", type: "radio", value: "#{string.upcase}")).to have_text(string)
  # elt = page.find("div.input_row:nth-child(#{row_offset})")
  # what_is elt
  within("div.input_row:nth-child(#{row_offset}) > fieldset > div.adv-search-control") do 
    find_field(string, :disabled => :all).set(true)
  end
end

When("I select {string} from the query logic drop-down on line {int}") do |string, int|
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

When("I enter {string} as the query on line {int}") do |string, int|
  id = "q_row#{int}"
  page.find_by_id(id).set("#{string}")
end
