module BlacklightUnapiHelper
  def render_document_unapi_microformat document, options = {}
    render :partial =>'unapi/microformat', :locals => {:document => document}.merge(options)
  end
end
