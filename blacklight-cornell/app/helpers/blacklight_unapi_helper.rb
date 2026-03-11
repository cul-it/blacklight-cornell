# frozen_string_literal: true

module BlacklightUnapiHelper
  def inject_auto_discovery_link_tag
    return if @injected_auto_discovery_link_tag

    content_for(:head) do
      tag.link(rel: "unapi-server", type: "application/xml", title: "unAPI", href: unapi_url)
    end

    @injected_auto_discovery_link_tag = true
  end
end
