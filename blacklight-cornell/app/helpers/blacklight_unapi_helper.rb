# frozen_string_literal: true

module BlacklightUnapiHelper
  def inject_auto_discovery_link_tag
    content_for(:head) do
      auto_discovery_link_tag(:unapi, unapi_url, type: 'application/xml', rel: 'unapi-server', title: 'unAPI')
    end unless @injected_auto_discovery_link_tag
    @injected_auto_discovery_link_tag = true
  end
end
