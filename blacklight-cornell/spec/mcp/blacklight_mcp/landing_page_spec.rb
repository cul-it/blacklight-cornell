# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

RSpec.describe BlacklightMcp::LandingPage do
  it 'updates the stylesheet fingerprint when CSS changes between renders' do
    allow(Rails.env).to receive(:development?).and_return(true)

    Dir.mktmpdir('mcp-assets') do |directory|
      css = File.join(directory, 'mcp.css')
      File.write(css, 'body { color: red; }')
      assets = Sprockets::Environment.new
      assets.append_path(directory)

      allow(ActionView::Base).to receive(:assets_environment).and_return(assets)
      allow(ActionView::Base).to receive(:resolve_assets_with).and_return([:environment])
      allow(ActionView::Base).to receive(:check_precompiled_asset).and_return(false)

      before_edit = described_class.stylesheet
      File.write(css, 'body { color: blue; background: white; }')
      # Sprockets 3 tracks mtimes at whole-second resolution.
      updated = File.mtime(css) + 2
      File.utime(updated, updated, css)

      after_edit = described_class.stylesheet
      expect(after_edit).not_to eq(before_edit)
      expect(after_edit).to include(assets['mcp.css'].digest_path)
    end
  end
end
