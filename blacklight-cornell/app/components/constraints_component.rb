# frozen_string_literal: true

class ConstraintsComponent < Blacklight::ConstraintsComponent
  def initialize(search_state:,
                 tag: :div,
                 render_headers: true,
                 id: 'appliedParams', classes: 'selected-facets',
                 query_constraint_component: Blacklight::ConstraintLayoutComponent,
                 query_constraint_component_options: {},
                 facet_constraint_component: Blacklight::ConstraintComponent,
                 facet_constraint_component_options: { },
                 start_over_component: StartOverButtonComponent)
    super
  end

  def render?
    @search_state.has_constraints? && params[:controller] != 'advanced_search'
  end

  def advanced_query_params
    @search_state.advanced_query_param
  end

  def advanced_query_constraints
    return ''.html_safe if advanced_query_params.blank?

    # Create deep copy of params to not alter original search params hash
    my_params = params.deep_dup
    my_params = helpers.remove_blank_rows(my_params)

    content = []
    my_params[:q_row].each_with_index do |query, i|
      # Constraint label
      query_label = helpers.search_field_def_for_key(my_params[:search_field_row][i])[:label]
      # Constraint label with boolean
      boolean_index = [i - 1, 0].max
      bool_arr = my_params[:boolean_row].values
      query_label = "#{bool_arr[boolean_index]} #{query_label}" if i > 0

      # Get search path minus the current row
      removed_params = my_params.deep_dup
      removed_params[:q_row].delete_at(i)
      removed_params[:search_field_row].delete_at(i)
      removed_params[:op_row].delete_at(i)
      # Reset number keys in boolean_row
      bool_arr.delete_at(boolean_index)
      removed_params[:boolean_row] = Hash[("1"..bool_arr.size.to_s).zip bool_arr]
      remove_path = search_catalog_path(removed_params)

      content << helpers.render(
          @query_constraint_component.new(
            search_state: @search_state,
            value: query,
            label: query_label,
            remove_path: remove_path,
            classes: 'query',
            **@query_constraint_component_options
          )
        )
    end

    content.join.html_safe
  end
end
