# Overrides BlacklightRangeLimit::RangeFormComponent
blacklight_range_limit_path = Gem::Specification.find_by_name('blacklight_range_limit').full_gem_path
require_dependency File.join(blacklight_range_limit_path, 'app/components/blacklight_range_limit/range_form_component.rb')

# Overrides BlacklightRangeLimit::RangeFormComponent
module BlacklightRangeLimit
  class RangeFormComponent < Blacklight::Component
    # Overrides #render_range_input to add data-dynamic=true to input field for pre-populating advanced search form
    # type is 'begin' or 'end'
    def render_range_input(type, input_label = nil, maxlength_override = nil)
      type = type.to_s

      default = if @facet_field.selected_range.is_a?(Range)
                  case type
                  when 'begin' then @facet_field.selected_range.first
                  when 'end' then @facet_field.selected_range.last
                  end
                end

      ### BEGIN CUSTOMIZATION
      html = number_field_tag("range[#{@facet_field.key}][#{type}]", default, data: { dynamic: true }, maxlength: maxlength_override || maxlength, class: "form-control text-center range_#{type}")
      ### END CUSTOMIZATION
      html += label_tag("range[#{@facet_field.key}][#{type}]", input_label, class: 'sr-only visually-hidden') if input_label.present?
      html
    end
  end
end
