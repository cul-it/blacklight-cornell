class AdvancedRangeLimitComponent < Blacklight::Component
  def initialize(facet_field:, layout: nil)
    @facet_field = facet_field
  end

  def label
   "#{@facet_field.facet_field.label} Range"
  end

  def field
    @facet_field.facet_field.field
  end

  def begin_val
    @facet_field.search_state.params.dig('range', 'pub_date_facet', 'begin')
  end

  def end_val
    @facet_field.search_state.params.dig('range', 'pub_date_facet', 'end')
  end
end