class InstitutionalRepositoriesController < ApplicationController

  before_action :heading

  def heading
    @heading='Search'
  end

  def index
    @query = params["q"].nil? ? '' : params["q"]
    @oq = @query
    @page = params["page"].nil? ?  1 : params["page"]
    @per_page = 10
    @results = BentoSearch.get_engine(:institutionalRepositories).search(@query, :oq => @oq,
      :per_page => @per_page, :page => @page)
  end
end
