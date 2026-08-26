# frozen_string_literal: true

# TODO: Remove this file when we upgrade blacklight_range_limit to v9
class RangeFacetComponent < BlacklightRangeLimit::RangeFacetComponent
  # Don't render if we have no values at all -- most commonly on a zero results page.
  # Normally we'll have at least a min and a max (of values in result set, solr returns),
  # OR a count of objects missing a value -- if we don't have ANY of that, there is literally
  # nothing we can display, and we're probably in a zero results situation.
  def render?
    (@facet_field.min.present? && @facet_field.max.present?) ||
      @facet_field.missing_facet_item.present?
  end
end
