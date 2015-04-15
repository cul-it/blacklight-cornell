module BentoSearch
  class WebDecorator < StandardDecorator

    def render_source_info
      parts = []
      if self.source_title.present?
        parts << _h.content_tag("span", self.source_title, :class => "source_title")
      end
      return _h.safe_join(parts, "")
    end
  end
end
