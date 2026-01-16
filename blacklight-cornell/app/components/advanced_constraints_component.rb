class AdvancedConstraintsComponent < ConstraintsComponent
  def initialize(search_state:)
    @search_state = search_state
    @facet_constraint_component = ConstraintComponent
  end

  def render?
    @search_state.filters.present?
  end

  private

    def facet_item_presenters
      return to_enum(:facet_item_presenters) unless block_given?

      simple_facets = @search_state.filters.select { |facet| params['f'].include?(facet.key) }

      Deprecation.silence(Blacklight::SearchState) do
        simple_facets.map do |facet|
          facet.values.map do |val|
            next if val.blank? || val.is_a?(Array)

            yield facet_item_presenter(facet.config, val, facet.key)
          end
        end
      end
    end
end
