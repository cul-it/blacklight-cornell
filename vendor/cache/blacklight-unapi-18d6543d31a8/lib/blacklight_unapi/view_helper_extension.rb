module BlacklightUnapi::ViewHelperExtension
  def render_document_partial doc, action_name, *args
    (super(doc, action_name, *args) + render_document_unapi_microformat(doc)).html_safe
  end
end
