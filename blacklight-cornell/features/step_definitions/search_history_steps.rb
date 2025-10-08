# ==============================================================================
# Count items in search history
# ------------------------------------------------------------------------------
Then('there should be {int} items in the Search History') do |expected|
  containers = ['.search-history', '#search_history', '#content', 'main', '#documents']
  item_selectors = [
    'a .custom-search-history-link',
    '.custom-search-history-link',
    '.document',
    '.document-row',
    '.search-history-item',
    'ul.search-history > li',
    'ul > li.document',
    'table tr.document',
    'article.document'
  ]

  chosen_container = containers.find { |sel| page.has_css?(sel) }
  chosen_container = page unless chosen_container
  scope = chosen_container == page ? page : page.find(chosen_container)

  actual = item_selectors.map { |sel| scope.all(sel).size }.max || 0
  expect(actual).to eq(expected)
end

# ==============================================================================
# Choose operator for advanced search rows.
# ------------------------------------------------------------------------------
When("I choose operator {string} for row {int}") do |value, row|
  idx = row.to_i - 1
  val = value.to_s.strip.upcase

  if %w[AND OR NOT].include?(val) && row.to_i > 1
    select(val, from: "boolean_row[#{idx}]")
  else
    mapped = case val
             when 'AND' then 'all'
             when 'OR'  then 'any'
             when 'NOT' then 'all'
             else value
             end
    select(mapped, from: "op_row#{idx}")
  end
end

# ==============================================================================
# Fill in an advanced search row.
# ------------------------------------------------------------------------------
When("I fill in advanced row {int} with {string} in field {string}") do |row, query, field_label|
  idx = row.to_i - 1
  find_by_id("q_row#{idx}").set(query)
  select(field_label, from: "search_field_row#{idx}")
end

# ==============================================================================
# Add an advanced-search row.
# ------------------------------------------------------------------------------
When("I add an advanced row") do
  if page.has_selector?(:id, "add-row")
    find_by_id("add-row").click
  else
    click_on("add-row")
  end
end

# ==============================================================================
# Select inclusive facet values.
# ------------------------------------------------------------------------------
When("I select inclusive facet {string} values {string}") do |facet_label, values_csv|
  values = values_csv.split(",").map(&:strip).reject(&:empty?)
  trigger = first(:xpath, %Q(
    //button[contains(normalize-space(.), "#{facet_label}")]
    | //a[contains(@class,"facet-field") and contains(normalize-space(.), "#{facet_label}")]
    | //h2[contains(normalize-space(.), "#{facet_label}")]
    | //h3[contains(normalize-space(.), "#{facet_label}")]
  ))
  trigger.click if trigger && %w[button a].include?(trigger.tag_name)

  container = (trigger&.sibling("div", match: :first) rescue nil) || page
  values.each { |val| within(container) { check(val) } }
end

# ==============================================================================
# Publication Year range.
# ------------------------------------------------------------------------------
When("I set the Publication Year range begin {string} and end {string}") do |begin_year, end_year|
  find_by_id("range_pub_date_facet_begin").set(begin_year)
  find_by_id("range_pub_date_facet_end").set(end_year)
end
