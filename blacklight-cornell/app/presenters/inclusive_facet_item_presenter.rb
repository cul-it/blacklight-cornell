# frozen_string_literal: true

class InclusiveFacetItemPresenter < Blacklight::InclusiveFacetItemPresenter
  def field_label
    "AND #{facet_field_presenter.label}"
  end
end
