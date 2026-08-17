require 'rails_helper'

RSpec.describe 'catalog/_request_buttons.html.erb', type: :view do
  let(:document) do
    {
      'location' => 'Olin Library',
      'callnum_sort' => 'QA76.73'
    }
  end

  let(:base_locals) do
    {
      group: 'Circulating',
      noncirc: false,
      aeon_codes: [],
      has_non_spif_items: true,
      reading: '',
      reserve_item: false,
      reserve_only: false,
      restricted_request_item: false
    }
  end

  def render_partial(extra_locals = {})
    render partial: 'catalog/request_buttons', locals: base_locals.merge(extra_locals)
  end

  before do
    assign(:document, document)
    assign(:title, 'Test Title')
    assign(:subtitle, 'Test Subtitle')

    allow(view).to receive(:params).and_return({ id: '123' })
    allow(view).to receive(:request_path).and_return('/request/path', '/scan/path')
    allow(view).to receive(:aspace_pui_url).and_return(nil)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('DISABLE_AEON').and_return(nil)
  end

  it 'renders the ILL scan link for circulating items when ILLIAD_URL is present' do
    allow(ENV).to receive(:[]).with('ILLIAD_URL').and_return('https://illiad.example.edu/OpenURL')

    render_partial

    expect(rendered).to have_link('Request scan of article/chapter')
  end

  it 'does not render the ILL scan link when ILLIAD_URL is missing' do
    allow(ENV).to receive(:[]).with('ILLIAD_URL').and_return(nil)

    render_partial

    expect(rendered).not_to include('Request scan of article/chapter')
  end

  it 'renders the archives request link when an ASpace URL is available' do
    allow(ENV).to receive(:[]).with('ILLIAD_URL').and_return(nil)
    allow(view).to receive(:aspace_pui_url).and_return('https://archives.example.edu/repositories/2/resources/2345')

    render_partial

    expect(rendered).to have_link('Request from Archives at Cornell', href: 'https://archives.example.edu/repositories/2/resources/2345')
  end

  it 'renders disabled request UI for reserve-only items' do
    allow(ENV).to receive(:[]).with('ILLIAD_URL').and_return(nil)

    render_partial(reserve_only: true)

    expect(rendered).to have_link('Request item', href: '#')
    expect(rendered).to include("This item is on reserve and can't be requested for delivery.")
  end

  it 'does not render request buttons for restricted-location items' do
    allow(ENV).to receive(:[]).with('ILLIAD_URL').and_return('https://illiad.example.edu/OpenURL')

    render_partial(restricted_request_item: true)

    expect(rendered).to be_blank
  end

  it 'renders a request button for a standard circulating item' do
    allow(ENV).to receive(:[]).with('ILLIAD_URL').and_return(nil)

    render_partial

    expect(rendered).to have_link('Request item', href: '/request/path')
  end
end