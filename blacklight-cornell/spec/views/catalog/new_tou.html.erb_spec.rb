require 'rails_helper'

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
            'interLibraryLoan' => [{
              'internal' => false,
              'type' => { 'label' => 'ILL Type' },
              'value' => { 'label' => 'Allowed' },
              'publicNote' => 'ILL note'
            }],
            'illGeneralSelect' => [{
              'internal' => false,
              'type' => { 'label' => 'ILL General' },
              'value' => { 'label' => 'General Allowed' },
              'publicNote' => 'General note'
            }],
            'illRecordKeepingSelect' => [{
              'internal' => false,
              'type' => { 'label' => 'Record Keeping' },
              'value' => { 'label' => 'Record Allowed' },
              'publicNote' => 'Record note'
            }],
            'illSecureElectronic' => [{
              'internal' => false,
              'type' => { 'label' => 'Secure Electronic' },
              'value' => { 'label' => 'Secure Allowed' },
              'publicNote' => 'Secure note'
            }],
            # Omit 'courseReserves' key entirely to test 'courseReserve'
            'courseReserve' => [{
              'internal' => false,
              'type' => { 'label' => 'Course Reserve' },
              'value' => { 'label' => 'Reserve Allowed' },
              'publicNote' => 'Reserve note'
            }],
            'scholarlySharing2' => [{
              'internal' => false,
              'type' => { 'label' => 'Scholarly Sharing 2' },
              'value' => { 'label' => 'Sharing2 Allowed' },
              'publicNote' => 'Sharing2 note'
            }],
            'scholarlySharing' => [{
              'internal' => false,
              'type' => { 'label' => 'Scholarly Sharing' },
              'value' => { 'label' => 'Sharing Allowed' },
              'publicNote' => 'Sharing note'
            }],
            'authorizedUsers2' => [{
              'internal' => false,
              'type' => { 'label' => 'Authorized Users 2' },
              'value' => { 'label' => 'User1;User2' }
            }],
            'authorizedUsers' => [{
              'internal' => false,
              'type' => { 'label' => 'Authorized Users' },
              'value' => 'User3;User4'
            }],
            'walkInAccess' => [{
              'internal' => false,
              'type' => { 'label' => 'Walk In' },
              'value' => { 'label' => 'Walk Allowed' },
              'publicNote' => 'Walk note'
            }],
            'concurrentAccess' => [{
              'internal' => false,
              'type' => { 'label' => 'Concurrent' },
              'value' => 'Concurrent Allowed',
              'publicNote' => 'Concurrent note'
            }],
            'remoteAccess' => [{
              'internal' => false,
              'type' => { 'label' => 'Remote' },
              'value' => { 'label' => 'Remote Allowed' },
              'publicNote' => 'Remote note'
            }],
            'otherRestrictions' => [{
              'internal' => false,
              'type' => { 'label' => 'Other Restrictions' },
              'value' => 'Other Value',
              'publicNote' => 'Other note'
            }],
            'generalPermissions2' => [{
              'internal' => false,
              'type' => { 'label' => 'General Permissions 2' },
              'value' => { 'label' => 'Perm2 Allowed' },
              'publicNote' => 'Perm2 note'
            }],
            'generalPermissions' => [{
              'internal' => false,
              'type' => { 'label' => 'General Permissions' },
              'value' => 'Perm Allowed',
              'publicNote' => 'Perm note'
            }],
            'generalRestrictions2' => [{
              'internal' => false,
              'type' => { 'label' => 'General Restrictions 2' },
              'value' => { 'label' => 'Restrict2 Allowed' }
            }],
            'generalRestrictions' => [{
              'internal' => false,
              'type' => { 'label' => 'General Restrictions' },
              'value' => 'Restrict Allowed',
              'publicNote' => 'Restrict note'
            }],
            'nondisclosure' => [{
              'internal' => false,
              'type' => { 'label' => 'Nondisclosure' },
              'value' => { 'label' => 'Nondisclosure Allowed' },
              'publicNote' => 'Nondisclosure note'
            }],
            'postCancellationAccess' => [{
              'internal' => false,
              'type' => { 'label' => 'Post Cancellation' },
              'value' => { 'label' => 'Post Allowed' },
              'publicNote' => 'Post note'
            }],
            'nonRenewalNoticePeriod' => [{
              'internal' => false,
              'type' => { 'label' => 'Non Renewal' },
              'value' => { 'label' => 'NonRenewal Allowed' },
              'publicNote' => 'NonRenewal note'
            }],
            'curePeriodBreachUnit' => [{
              'internal' => false,
              'type' => { 'label' => 'Cure Period' },
              'value' => { 'label' => 'Cure Allowed' }
            }],
            'governingLaw' => [{
              'internal' => false,
              'type' => { 'label' => 'Governing Law' },
              'value' => { 'label' => 'Law Allowed' },
              'publicNote' => 'Law note'
            }],
            'fairUseClause' => [{
              'internal' => false,
              'type' => { 'label' => 'Fair Use' },
              'value' => { 'label' => 'Fair Allowed' },
              'publicNote' => 'Fair note'
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

    it "renders all custom fields if present" do
      # interLibraryLoan
      expect(rendered).to have_content("ILL Type")
      expect(rendered).to have_content("Allowed")
      expect(rendered).to have_content("ILL note")
      # illGeneralSelect
      expect(rendered).to have_content("ILL General")
      expect(rendered).to have_content("General Allowed")
      expect(rendered).to have_content("General note")
      # illRecordKeepingSelect
      expect(rendered).to have_content("Record Keeping")
      expect(rendered).to have_content("Record Allowed")
      expect(rendered).to have_content("Record note")
      # illSecureElectronic
      expect(rendered).to have_content("Secure Electronic")
      expect(rendered).to have_content("Secure Allowed")
      expect(rendered).to have_content("Secure note")
      # courseReserve
      expect(rendered).to have_content("Course Reserve")
      expect(rendered).to have_content("Reserve Allowed")
      expect(rendered).to have_content("Reserve note")
      # scholarlySharing2
      expect(rendered).to have_content("Scholarly Sharing 2")
      expect(rendered).to have_content("Sharing2 Allowed")
      expect(rendered).to have_content("Sharing2 note")
      # authorizedUsers2 (no gsub, so expect semicolon)
      expect(rendered).to have_content("Authorized Users 2")
      expect(rendered).to have_content("User1;User2")
      # walkInAccess
      expect(rendered).to have_content("Walk In")
      expect(rendered).to have_content("Walk Allowed")
      expect(rendered).to have_content("Walk note")
      # concurrentAccess
      expect(rendered).to have_content("Concurrent")
      expect(rendered).to have_content("Concurrent Allowed")
      expect(rendered).to have_content("Concurrent note")
      # remoteAccess
      expect(rendered).to have_content("Remote")
      expect(rendered).to have_content("Remote Allowed")
      expect(rendered).to have_content("Remote note")
      # otherRestrictions
      expect(rendered).to have_content("Other Restrictions")
      expect(rendered).to have_content("Other Value")
      expect(rendered).to have_content("Other note")
      # generalPermissions2
      expect(rendered).to have_content("General Permissions 2")
      expect(rendered).to have_content("Perm2 Allowed")
      expect(rendered).to have_content("Perm2 note")
      # generalRestrictions2
      expect(rendered).to have_content("General Restrictions 2")
      expect(rendered).to have_content("Restrict2 Allowed")
      # nondisclosure
      expect(rendered).to have_content("Nondisclosure")
      expect(rendered).to have_content("Nondisclosure Allowed")
      expect(rendered).to have_content("Nondisclosure note")
      # postCancellationAccess
      expect(rendered).to have_content("Post Cancellation")
      expect(rendered).to have_content("Post Allowed")
      expect(rendered).to have_content("Post note")
      # nonRenewalNoticePeriod
      expect(rendered).to have_content("Non Renewal")
      expect(rendered).to have_content("NonRenewal Allowed")
      expect(rendered).to have_content("NonRenewal note")
      # curePeriodBreachUnit
      expect(rendered).to have_content("Cure Period")
      expect(rendered).to have_content("Cure Allowed")
      # governingLaw
      expect(rendered).to have_content("Governing Law")
      expect(rendered).to have_content("Law Allowed")
      expect(rendered).to have_content("Law note")
      # fairUseClause
      expect(rendered).to have_content("Fair Use")
      expect(rendered).to have_content("Fair Allowed")
      expect(rendered).to have_content("Fair note")
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
