# Helper methods for the advanced search form
module AdvancedHelper
  def advanced_search_field_select_opts
    @advanced_search_field_select_opts ||= begin
        # make it an ActiveSupport::OrderedHash if it needs to be
        hash = blacklight_config.search_fields.class.new
        blacklight_config.search_fields.select do |field, field_config|
          hash[field] = field_config unless field_config.include_in_advanced_search == false
        end

        hash.collect{|field, field_config| [field_config.label, field_config.field]}
      end
  end

  def advanced_search_sort_opts
    @advanced_search_sort_opts ||= active_sort_fields.each_with_object([]) do |(sort_key, field_config), sort_options|
      sort_options << [sort_field_label(sort_key), search_state.params_for_search(sort: sort_key)['sort']]
    end
  end

  def strip_quotes(str)
    str.sub(/\A['"]/, "").sub(/['"]\z/, "")
  end

  def prep_query(raw_query)
    query = raw_query.strip

    # Remove quotes if single word query
    query = strip_quotes(query) unless query.include?(' ')

    # Sanitize to prevent HTML injection
    query = ActionView::Base.full_sanitizer.sanitize(query)

    # Marks query as safe post-sanitization, so special characters aren't further escaped in view
    query.html_safe
  end

  def default_form_values(params)
    [
      { q: params[:q], search_field: params[:search_field] },
      {}
    ]
  end

  def params_to_form_values(params)
    q_row = params[:q_row] || []
    op_row = params[:op_row] || []
    search_field_row = params[:search_field_row] || []
    boolean_row = params[:boolean_row] || {}

    form_values = []
    q_row.count.times do |i|
      row = {
        q: prep_query(q_row[i]),
        op: op_row[i] || 'AND',
        search_field: search_field_row[i] || 'all_fields'
      }
      row.merge!(boolean: boolean_row[i.to_s] || 'AND') if i > 0
      form_values << row
    end

    form_values
  end

  def params_to_hidden_form_values(params)
    return [] if params[:f].nil?

    hidden_filters = []
    params[:f].each do |key, value|
      value.each do |name|
        hidden_filters << { name: "f[#{key}][]", value: name }
      end
    end
    hidden_filters
  end
end
