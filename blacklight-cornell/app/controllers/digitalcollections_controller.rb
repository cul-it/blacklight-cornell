# -*- encoding : utf-8 -*-
class DigitalcollectionsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  include BlacklightUnapi::ControllerExtension
  before_action :heading

  def heading
   @heading='Digital Collections'
  end

  def index
    @digRegResponse = Blacklight.default_index.connection.get('culdigreg', params: { q: '*' })
    @digReg = @digRegResponse['response']['docs']
  end

  def searchdigreg
    if params[:q].nil? or params[:q] == ""
      flash.now[:error] = "Please enter a query."
      render "index"
    end
    if !params[:q].nil? and params[:q] != ""
      p = {"q" =>params[:q] } #TODO: This doesn't seem to be used. Should we delete this?
      response = Blacklight.default_index.connection.get('culdigreg', params: { q: params[:q] })
      @digregResponse = response['response']['docs']
      params[:q].gsub!('%20', ' ')
    end
  end
end
