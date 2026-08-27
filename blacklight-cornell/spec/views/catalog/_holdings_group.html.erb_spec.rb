require 'rails_helper'

RSpec.describe 'catalog/_holdings_group.html.erb', type: :view do
  let(:document) do
    {
      'multivol_b' => nil,
      'location' => 'Olin Library',
      'callnum_sort' => 'PS123 .A1'
    }
  end

  def build_item(location_code)
    {
      'call' => 'PS123 .A1',
      'circ' => true,
      'location' => { 'code' => location_code, 'name' => 'Olin Library' }
    }
  end

  def render_partial(items:, group: 'Circulating')
    render partial: 'catalog/holdings_group', locals: { items: items, group: group }
  end

  before do
    assign(:document, document)
    assign(:title, 'Test Title')
    assign(:subtitle, 'Test Subtitle')

    allow(view).to receive(:params).and_return({ id: '123' })
    allow(view).to receive(:request_path).and_return('/request/path', '/scan/path')
    allow(view).to receive(:session).and_return({ search: { counter: 1 } })
    allow(view).to receive(:aspace_pui_url).and_return(nil)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('DISABLE_AEON').and_return(nil)
    allow(ENV).to receive(:[]).with('ILLIAD_URL').and_return(nil)
  end

  it 'renders the request item link for an item at a standard location' do
    render_partial(items: [build_item('olin,stacks')])

    expect(rendered).to have_link('Request item', href: '/request/path')
  end

  it 'suppresses the request buttons for an item at the restricted olin,701 location' do
    render_partial(items: [build_item('olin,701')])

    expect(rendered).not_to have_link('Request item')
  end

  context 'DACCESS-979 circulating copy plus an aspace collection' do
    before do
      allow(view).to receive(:aspace_pui_url)
        .and_return('https://archives.example.edu/repositories/2/resources/2345')
    end

    it 'renders the request item button for the circulating group' do
      render_partial(items: [build_item('olin,anx')])

      expect(rendered).to have_link('Request item', href: '/request/path')
      expect(rendered).not_to have_link('Request from Archives at Cornell')
    end

    it 'renders the archives link for the rare group' do
      render_partial(items: [build_item('rmc,anx')], group: 'Rare')

      expect(rendered).to have_link('Request from Archives at Cornell')
      expect(rendered).not_to have_link('Request item', exact: true)
    end
  end

  context 'circulating copy plus a rare copy requestable via Aeon reading room' do
    it 'renders the request item button for the circulating group' do
      render_partial(items: [build_item('olin')])

      expect(rendered).to have_link('Request item', href: '/request/path')
      expect(rendered).not_to have_link('Request item for Reading Room Delivery')
    end

    it 'renders the Aeon reading room and scan buttons for the rare group' do
      render_partial(items: [build_item('rmc')], group: 'Rare')

      expect(rendered).to have_link('Request item for Reading Room Delivery')
      expect(rendered).to have_link('Request item for scanning')
      expect(rendered).not_to have_link('Request item', exact: true)
    end
  end
end
