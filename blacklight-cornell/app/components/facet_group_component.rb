# frozen_string_literal: true

# Render a group of facet fields
class FacetGroupComponent < Blacklight::Response::FacetGroupComponent

  # Overridden from Blacklight core: `body.present?` is always true once a
  # body slot has been assigned.
  # Forcing #to_s renders the slot content so we check the actual HTML for blankness.
  def render?
    body.to_s.present?
  end
end
