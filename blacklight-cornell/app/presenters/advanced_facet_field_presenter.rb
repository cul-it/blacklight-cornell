class AdvancedFacetFieldPresenter < Blacklight::FacetFieldPresenter
  # Collapse all facets by default unless in params
  def collapsed?
    !active?
  end
end
