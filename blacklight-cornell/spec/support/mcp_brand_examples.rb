# frozen_string_literal: true

# The Cornell University Library lockup, as the Library branding guide has it:
# the red lockup on a light background, the white lockup on a dark one. The
# landing page carries it from its own partial.
RSpec.shared_examples 'a page carrying the library lockup' do
  it 'shows the red lockup, swapping to the white one in dark mode' do
    expect(response.body).to include('src="/img/CULibraryRed.svg"')
    expect(response.body).to match(%r{<source srcset="/img/CULibraryWhite.svg" media="\(prefers-color-scheme: dark\)">})
  end

  it 'names the library for a screen reader and links to it' do
    expect(response.body).to include('alt="Cornell University Library"', 'href="https://www.library.cornell.edu/"')
  end

  # The guide's minimum seal height for digital use.
  it 'sizes the seal at least 120 pixels tall' do
    expect(response.body).to match(/class="mcp-lockup"[^>]*height="120"/)
  end
end
