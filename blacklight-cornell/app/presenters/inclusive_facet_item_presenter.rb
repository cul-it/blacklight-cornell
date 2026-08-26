# frozen_string_literal: true

class InclusiveFacetItemPresenter < Blacklight::InclusiveFacetItemPresenter
  # Overrides Blacklight::InclusiveFacetItemPresenter defaults to prepend "AND" to f_inclusive facet constraint field label
  def field_label
    "AND #{facet_field_presenter.label}"
  end
end
