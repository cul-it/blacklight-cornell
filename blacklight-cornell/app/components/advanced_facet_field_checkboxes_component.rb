# frozen_string_literal: true

# Custom FacetFieldCheckboxesComponent to prefill facet checkboxes with f_inclusive values in advanced search form
# Can remove this in blacklight >= v8.4.0: https://github.com/projectblacklight/blacklight/pull/3278/files
class AdvancedFacetFieldCheckboxesComponent < Blacklight::FacetFieldCheckboxesComponent
  def presenters
    return [] unless @facet_field.paginator

    return to_enum(:presenters) unless block_given?

    @facet_field.paginator.items.each do |item|
      yield Blacklight::FacetCheckboxItemPresenter.new(item, @facet_field.facet_field, helpers, @facet_field.key, @facet_field.search_state)
    end
  end
end