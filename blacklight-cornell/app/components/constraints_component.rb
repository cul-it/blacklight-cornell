class ConstraintsComponent < Blacklight::ConstraintsComponent
  def initialize(search_state:,
                 tag: :div,
                 render_headers: true,
                 id: 'appliedParams', classes: 'selected-facets',
                 query_constraint_component: ConstraintLayoutComponent,
                 query_constraint_component_options: {},
                 facet_constraint_component: ConstraintComponent,
                 facet_constraint_component_options: {},
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
    my_params = remove_blank_rows(my_params)

    # Treat single row as a simple search
    if my_params[:q_row].count == 1
      # Set simple search params
      @search_state.params[:search_field] = my_params[:search_field_row][0]
      @search_state.params[:q] = my_params[:q_row][0]

      return query_constraints
    end

    content = ''
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

    content.html_safe
  end

  private

  # TODO: Similar to SearchBuilder#remove_blank_rows - can this be DRY-ed up?
  def remove_blank_rows(my_params = params || {})
    cleaned_params = { q_row: [], op_row: [], search_field_row: [], boolean_row: {} }
    row_count = my_params[:q_row].count
    row_count.times do |i|
      if my_params[:q_row][i].strip.present?
        cleaned_params[:q_row] << my_params[:q_row][i]
        cleaned_params[:op_row] << (my_params.fetch(:op_row, [])[i] || DEFAULT_OP)
        cleaned_params[:search_field_row] << (my_params.fetch(:search_field_row, [])[i] || DEFAULT_SEARCH_FIELD)
      end

      # Don't add last bool in boolean_row
      if cleaned_params[:q_row].present? && my_params[:q_row][i + 1].present?
        old_boolean_row_key = (i + 1).to_s
        cleaned_boolean_row_key = cleaned_params[:q_row].count.to_s
        cleaned_params[:boolean_row][cleaned_boolean_row_key] = (my_params.dig(:boolean_row, old_boolean_row_key) || DEFAULT_BOOLEAN)
      end
    end

    my_params.merge(cleaned_params)
  end
end
