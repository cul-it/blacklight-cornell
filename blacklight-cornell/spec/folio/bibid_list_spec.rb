require "rails_helper"

RSpec.describe "Browse search", type: :feature do
  describe "displaying titles for bibids" do
    [
      { bibid: "1001", title: "Reflections" },
      { bibid: "1003756", title: "Struktura filosofskogo znanii︠a︡" },
      { bibid: "10055679", title: "Big chicken" },
    # Add the rest of the bibid and title pairs here
    ].each do |pair|
      it "displays the title '#{pair[:title]}' for bibid #{pair[:bibid]}" do
        visit "/catalog/#{pair[:bibid]}" # Adjust the path as necessary for your application
        expect(page).to have_content(pair[:title])
      end
    end
  end
end
