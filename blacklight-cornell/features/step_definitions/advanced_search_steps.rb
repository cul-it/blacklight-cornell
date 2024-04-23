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
  page.find_by_id(op).select( "#{logic}")
  page.find_by_id(fid).select( "#{field}")
end

When("I do the advanced search") do
  page.find_by_id("advanced_search").click
end

When("I view the {string} version of the search results") do |format|
  # Get the current URL
  current = URI.parse(current_url).path

  atom_formats = ['xml', 'dc_xml', 'oai_dc_xml', 'ris', 'zotero', 'rdf_zotero']

  if atom_formats.include? format
    new_url = current.gsub('/catalog.html?', "/catalog.atom?content_format=#{format}")
  else
    # Substitute 'catalog' with 'catalog.json'
    new_url = current.gsub('/catalog?', "/catalog.#{format}?")
  end

  # Visit the new URL
  visit new_url
end
