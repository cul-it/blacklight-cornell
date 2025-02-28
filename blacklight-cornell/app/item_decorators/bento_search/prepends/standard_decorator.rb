# Based on the Module#prepend pattern in ruby.
# Uses the to_prepare Rails hook in bento_search initializer to inject this module to override BentoSearch::StandardDecorator
module BentoSearch
  module Prepends::StandardDecorator

    # Overrides #author_display from gem to handle when author is missing
    # How to display a BentoSearch::Author object as a name
    def author_display(author)
      if author.present?
        if (author.first.present? && author.last.present?)
          "#{author.last}, #{author.first.slice(0,1)}"
        elsif author.display.present?
          author.display
        elsif author.last.present?
          author.last
        else
          nil
        end
      else
        nil
      end
    end

    # Overrides #render_source_info from gem to remove citation details and tweak punctuation
    # Returns source publication name OR publisher, along with volume/issue/pages
    # if present, all wrapped in various tags and labels. Returns html_safe
    # with tags.
    #
    # Experiment to do this in a decorator helper instead of a partial template,
    # might be more convenient we think.
    def render_source_info
      parts = []

      if self.source_title.present?
        parts << _h.content_tag("span", I18n.t("bento_search.published_in"), :class=> "source_label")
        parts << _h.content_tag("span", self.source_title, :class => "source_title")
        parts << ". "
      elsif self.publisher.present?
        parts << _h.content_tag("span", self.publisher, :class => "publisher")
      end

      return _h.safe_join(parts, "")
    end
  end
end
