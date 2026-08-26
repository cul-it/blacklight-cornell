# frozen_string_literal: true

class InclusiveFacetItemPresenter < Blacklight::InclusiveFacetItemPresenter
  # Overrides Blacklight::InclusiveFacetItemPresenter defaults to prepend "AND" to f_inclusive facet constraint field label when "OR" is present in value display
  def field_label
    label = facet_field_presenter.label
    Array(facet_item).count > 1 ? "AND #{label}" : label
  end
end
