module Blacklight::Marc
  module Catalog
    extend ActiveSupport::Concern

    def librarian_view
      @document = search_service.fetch(params[:id])

      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end
  end
end
