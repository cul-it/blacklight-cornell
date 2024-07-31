When("I select {string} from the row logic radio before line {int}") do |string, int|
  row_offset = int
  within("div.input_row:nth-child(#{row_offset}) > fieldset > div.adv-search-control") do
    find_field(string, :disabled => :all).set(true)
  end
end

When("I use {string} with {string} logic for field {string} on line {int} of advanced search") do |query, logic, field, line|
  id = "q_row#{line}"
  if line == 1
    op = "op_row"
    fid = "search_field_advanced"
  else
    op = "op_row#{line}"
    fid = "search_field_advanced#{line}"
  end
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

Then("the solr query should be {string}") do |string|
  sq = page.find("dl#solr-query-display > dd").text
  expect(sq).to eq(string)
end

Then("the solr query should contain {string}") do |string|
  sq = page.find("dl#solr-query-display > dd").text
  expect(sq).to match(string)
end
