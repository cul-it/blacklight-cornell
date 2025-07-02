require 'rails_helper'

RSpec.describe AdvancedRangeLimitComponent, type: :component do
  subject(:component) { described_class.new(facet_field: facet_field) }

  let(:rendered) { Capybara::Node::Simple.new(render_inline(component)) }

  let(:facet_field) do
    instance_double(
      BlacklightRangeLimit::FacetFieldPresenter,
      key: 'pub_date_facet',
      label: 'Publication Year',
      search_state: BlacklightCornell::SearchState.new(facet_field_params, nil),
      facet_field: facet_config
    )
  end

  let(:facet_config) do
    Blacklight::Configuration::FacetField.new(key: 'pub_date_facet', item_presenter: BlacklightRangeLimit::FacetItemPresenter)
  end

  let(:facet_field_params) { {} }

  it 'renders the range field label' do
    expect(rendered).to have_selector('label.col-form-label', text: 'Publication Year Range')
  end

  it 'render empty input fields' do
    expect(rendered.find('input#range_pub_date_facet_begin').value).to be_nil
    expect(rendered.find('input#range_pub_date_facet_end').value).to be_nil
  end

  context 'with range params' do
    let(:facet_field_params) do
      {
        range: {
          pub_date_facet: {
            begin: '2000',
            end: '2020'
          }
        }
      }
    end

    it 'prefills inputs from range params' do
      expect(rendered).to have_field('range_pub_date_facet_begin', with: '2000')
      expect(rendered).to have_field('range_pub_date_facet_end', with: '2020')
    end
  end

  context 'with empty range params' do
    let(:facet_field_params) do
      {
        range: {
          pub_date_facet: {
            begin: '',
            end: ''
          }
        }
      }
    end

    it 'renders empty input fields' do
      expect(rendered).to have_field('range_pub_date_facet_begin', with: '')
      expect(rendered).to have_field('range_pub_date_facet_end', with: '')
    end
  end
end
