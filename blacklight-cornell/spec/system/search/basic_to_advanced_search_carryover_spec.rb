require 'rails_helper'

RSpec.describe 'Basic Search to Advanced Search Carryover', type: :system do
  context 'When user types in basic search form' do
    it 'can have same text carryover to advanced search without submitting search' do
      visit root_path
      assert_text "Search..."
      fill_in 'q', with: 'Test Query'
      assert_text "Advanced Search"
      click_on "Advanced Search"
      expect(find('#q_row0').value).to eq('Test Query')
    end

    it 'can have same text and selected title field carryover to advanced search without submitting search' do
      visit root_path
      assert_text "Search..."
      fill_in 'q', with: 'Test Query'
      select 'Title', from: 'search_field'
      assert_text "Advanced Search"
      click_on "Advanced Search"
      expect(find('#q_row0').value).to eq('Test Query')
      expect(find('#search_field_advanced0').value).to eq('title')
    end

    it 'can have same text and selected field carryover to advanced search for all fields' do
      visit root_path
      assert_text "Search..."
      fill_in 'q', with: 'Test Query'
      # Define all field options to test
      field_options = {
        'All Fields' => 'all_fields',
        'Title' => 'title',
        'Journal Title' => 'journaltitle',
        'Title Begins With' => 'title',
        'Author' => 'author',
        'Author Browse (A-Z) Sorted By Name' => 'author',
        'Author Browse (A-Z) Sorted By Title' => 'author',
        'Subject' => 'subject',
        'Subject Browse (A-Z)' => 'subject',
        'Call Number' => 'lc_callnum',
        'Call Number Browse' => 'lc_callnum',
        'Publisher' => 'publisher',
      }

      # Iterate through each field option and test carryover
      field_options.each do |field_name, field_value|
        select field_name, from: 'search_field'
        assert_text "Advanced Search"
        click_on "Advanced Search"
        # Verify that the query text carried over
        expect(find('#q_row0').value).to eq('Test Query')
        # Verify that the selected field carried over
        expect(find('#search_field_advanced0').value).to eq(field_value)
        # Navigate back to the root_path for the next iteration
        visit root_path
        fill_in 'q', with: 'Test Query'
      end
    end

    it 'can have same text carryover to advanced search after submitting search' do
      visit root_path
      assert_text "Search..."
      fill_in 'q', with: 'Food'
      click_button 'search-btn'
      expect(page).to have_link("Library Catalog", href: "/")
      click_on 'Advanced Search', id: 'advanced-search-link'
      expect(find('#q_row0').value).to eq('Food')
    end
  end

  it 'does not carry over when search field is left blank' do
    visit root_path
    assert_text "Search..."
    assert_text "Advanced Search"
    click_on "Advanced Search"
    expect(find('#q_row0').value).to eq('')
  end

  it 'handles URI too large error gracefully' do
    large_text = 'A' * 10_000
    visit root_path
    assert_text "Search..."
    fill_in 'q', with: large_text
    assert_text "Advanced Search"
    click_on "Advanced Search"
    expect(page).to have_content("Request-URI Too Large")
  end

  it 'handles special characters in input text' do
    special_text = '!@#$%^&*()_+{}:"<>?~`-=[];,./'
    visit root_path
    assert_text "Search..."
    fill_in 'q', with: special_text
    assert_text "Advanced Search"
    click_on "Advanced Search"
    expect(find('#q_row0').value).to eq(special_text)
  end
end