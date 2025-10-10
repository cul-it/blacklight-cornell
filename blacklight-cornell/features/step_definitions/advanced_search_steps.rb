When("I select {string} from the boolean dropdown on line {int}") do |string, int|
  page.find_by_id("boolean_row\[#{int - 1}\]").select(string)
end

When("I use {string} with {string} logic for field {string} on line {int} of advanced search") do |query, logic, field, line|
  id = "q_row#{line - 1}"
  op = "op_row#{line - 1}"
  fid = "search_field_row#{line-1}"
  page.find_by_id(id).set("#{query}")
  page.find_by_id(op).select("#{logic}")
  page.find_by_id(fid).select("#{field}")
end

When("I view the {string} version of the search results") do |format|
  # Get the current URL
  uri = URI.parse(current_url)

  atom_formats = ["xml", "dc_xml", "oai_dc_xml", "ris", "mendeley", "zotero", "rdf_zotero"]

  if atom_formats.include? format
    uri.path = "/catalog.atom"
    params = CGI.parse(uri.query.to_s)
    params["content_format"] = format
    uri.query = URI.encode_www_form(params)
  else
    # Substitute 'catalog' with 'catalog.<format>'
    uri.path = "/catalog." + format
  end
  new_url = uri.to_s

  # Visit the new URL
  visit new_url
end

Then /^the solr query should be '(.*?)'$/ do |string|
  sq = page.find("dl#solr-query-display > dd").text
  expect(sq).to eq(string)
end

Then("the solr query should contain {string}") do |string|
  sq = page.find("dl#solr-query-display > dd").text
  expect(sq).to match(string)
end


#######################################-----------------------------------------
##  Steps for Year Range validation  ##
#######################################
When("I focus the start year field") do
  find('#range_pub_date_facet_begin, [data-date-start]', match: :first, visible: :all).click
end

When("I focus the end year field") do
  find('#range_pub_date_facet_end, [data-date-end]', match: :first, visible: :all).click
end

When("I type {string} into the focused field") do |text|
  active = page.driver.browser.switch_to.active_element
  active.send_keys(text) #simulate incremental typing ('300' before '3000').
end

When("Leave from the date range section of the form") do
  2.times { page.driver.browser.switch_to.active_element.send_keys(:tab) }
end

Then("the date range alert should be hidden") do
  if page.has_css?('#date-range-error')
    expect(page).to have_css('#date-range-error', visible: :hidden)
  end
end

Then("the date range alert should be visible with message {string}") do |msg|
  using_wait_time 3 do
    expect(page).to have_css('#date-range-error')
  end
  within('#date-range-error') do
    expect(page).to have_css('.msg', text: msg)
  end
  expect(page).to have_css('#date-range-error', visible: :visible)
end

Then("the advanced search submit button should be disabled") do
  btn = find('#advanced_search', visible: :all)
  disabled_attr = btn[:disabled]
  expect(disabled_attr).to be_truthy
  expect(btn[:class].to_s).to include('is-disabled')
end

Then("the advanced search submit button should be enabled") do
  using_wait_time 3 do
    expect(page.evaluate_script("document.querySelector('#advanced_search')?.disabled === false")).to be true
  end
end

Then("the start year field should be invalid") do
  el = find('#range_pub_date_facet_begin, [data-date-start]', match: :first, visible: :all)
  expect(el[:class].to_s).to include('is-invalid')
  expect(el['aria-invalid']).to eq('true')
  expect(el[:title].to_s.strip).not_to eq('')
end

Then("the end year field should be invalid") do
  el = find('#range_pub_date_facet_end, [data-date-end]', match: :first, visible: :all)
  expect(el[:class].to_s).to include('is-invalid')
  expect(el['aria-invalid']).to eq('true')
  expect(el[:title].to_s.strip).not_to eq('')
end
