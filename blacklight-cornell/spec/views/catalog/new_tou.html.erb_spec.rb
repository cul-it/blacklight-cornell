require 'rails_helper'

def custom_property(key)
  {
    'internal' => false,
    'type' => { 'label' => key.split(/(?=[A-Z])/).map(&:capitalize).join(' ') },
    'value' => { 'label' => "#{key} Allowed" },
    'publicNote' => "#{key} note"
  }
end

RSpec.describe "catalog/new_tou.html.erb", type: :view do
  let(:params) { { "id" => "123" } }

  before do
    allow(view).to receive(:params).and_return(params)
  end

  context "when @newTouResult is present" do
    let(:tou_data) do
      [
        {
          'name' => 'Test Resource',
          'customProperties' => {
            'interLibraryLoan' => [custom_property('interLibraryLoan')],
            'illGeneralSelect' => [custom_property('illGeneralSelect')],
            'illRecordKeepingSelect' => [custom_property('illRecordKeepingSelect')],
            'illSecureElectronic' => [custom_property('illSecureElectronic')],
            # Omit 'courseReserves' key entirely to test 'courseReserve'
            'courseReserve' => [custom_property('courseReserve')],
            'scholarlySharing2' => [custom_property('scholarlySharing2')],
            'scholarlySharing' => [custom_property('scholarlySharing')],
            'authorizedUsers2' => [custom_property('authorizedUsers2')],
            'authorizedUsers' => [custom_property('authorizedUsers')],
            'walkInAccess' => [custom_property('walkInAccess')],
            'concurrentAccess' => [custom_property('concurrentAccess')],
            'remoteAccess' => [custom_property('remoteAccess')],
            'otherRestrictions' => [custom_property('otherRestrictions')],
            'generalPermissions2' => [custom_property('generalPermissions2')],
            'generalPermissions' => [custom_property('generalPermissions')],
            'generalRestrictions2' => [custom_property('generalRestrictions2')],
            'generalRestrictions' => [custom_property('generalRestrictions')],
            'nondisclosure' => [custom_property('nondisclosure')],
            'postCancellationAccess' => [custom_property('postCancellationAccess')],
            'nonRenewalNoticePeriod' => [custom_property('nonRenewalNoticePeriod')],
            'curePeriodBreachUnit' => [custom_property('curePeriodBreachUnit')],
            'governingLaw' => [custom_property('governingLaw')],
            'fairUseClause' => [custom_property('fairUseClause')],
            'internalField1' => [{
              'internal' => true,
              'type' => { 'label' => 'Internal Field 1' },
              'value' => { 'label' => 'Internal Value' },
              'publicNote' => 'Internal note'
            }]
          }
        }
      ]
    end

    before do
      assign(:newTouResult, tou_data)
      render
    end

    it "renders the page title and back link" do
      expect(rendered).to have_content("Terms of Use")
      expect(rendered).to have_link("Back to Item", href: "/catalog/123")
    end

    it "renders the resource name" do
      expect(rendered).to have_content("Test Resource")
    end

    it "renders all non-internal custom fields if present" do
      custom_props = tou_data[0]['customProperties']
      tou_data[0]['customProperties'].each do |key, value_arr|
        next if value_arr.first['internal']
        # Skip suppressed properties if their '2' or plural variant is present
        next if key == 'scholarlySharing' && custom_props.key?('scholarlySharing2')
        next if key == 'authorizedUsers' && custom_props.key?('authorizedUsers2')
        next if key == 'generalPermissions' && custom_props.key?('generalPermissions2')
        next if key == 'generalRestrictions' && custom_props.key?('generalRestrictions2')
        next if key == 'courseReserve' && custom_props.key?('courseReserves')
        # Titleized label for the header
        label = key.split(/(?=[A-Z])/).map(&:capitalize).join(' ')
        expect(rendered).to have_content(label)
        # Display the value label or value string
        value = value_arr.first['value']
        allowed = value.is_a?(Hash) ? value['label'] : value
        expect(rendered).to have_content(allowed)
        # Display the note if present
        expect(rendered).to have_content(value_arr.first['publicNote']) if value_arr.first['publicNote']
      end
    end

    it "does not render internal custom fields" do
      expect(rendered).not_to have_content("internalField1")
    end
  end

  context "when @newTouResult is an empty array" do
    before do
      assign(:newTouResult, [])
      render
    end

    it "renders the default permissions table" do
      expect(rendered).to match(/General\s+Permissions/)
      expect(rendered).to match(/Authorized\s+Users\s+may\s+electronically\s+display,\s+download,\s+print,\s+and\s+digitally\s+copy\s+a\s+reasonable\s+portion/m)
      expect(rendered).to match(/General\s+Restrictions/)
      expect(rendered).to match(/Authorized\s+users\s+are\s+not\s+permitted\s+to\s+modify\s+or\s+create\s+a\s+derivative\s+work\s+of\s+the\s+Licensed\s+Materials/m)
    end
  end
end
