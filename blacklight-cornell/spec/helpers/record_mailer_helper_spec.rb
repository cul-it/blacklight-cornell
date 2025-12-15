require "rails_helper"

RSpec.describe RecordMailerHelper, type: :helper do

  describe '#render_email_fields' do
    let (:semantics) { { :author => ["Author"], :format => ["Book", "Video"] } }
    
    it "renders a single-value email field correctly" do
        email_field = render_email_field(semantics, "author")
        expect(email_field).to eq("<p>Author: Author</p>".html_safe)
    end

    it "renders a multi-value email field correctly" do
        email_field = render_email_field(semantics, "format")
        expect(email_field).to eq("<p>Format: Book; Video</p>".html_safe)
    end

    it "returns empty if there isn't a matching semantic value" do
        email_field = render_email_field(semantics, "language")
        expect(email_field).to eq("")
      end
  end
end