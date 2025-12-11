# -*- encoding : utf-8 -*-
class DatabasesController < ApplicationController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  #include BlacklightUnapi::ControllerExtension
  before_action :heading

  def heading
   @heading='Databases'
  end

  def subject
    Appsignal.increment_counter('db_search_subject', 1)
    subject_response = Blacklight.default_index.connection.get('databasesBySubject', params: { q: "\"#{params[:q]}\"" })
    @subject = subject_response['response']['docs']

    subject_core_response = Blacklight.default_index.connection.get('databasesBySubject', params: { q: "\"#{params[:q]} (Core)\"" })
    @subjectCore = subject_core_response['response']['docs']
    params[:q].gsub!('%20', ' ')
  end

  def title
    Appsignal.increment_counter('db_search_title', 1)
    response = Blacklight.default_index.connection.get('databaseAlphaBuckets', params: { q: "\"#{params[:alpha]}\"" })
    @a = response['response']['docs']
  end

  def show
    Appsignal.increment_counter('db_search_show', 1)
    @dbResponse = Blacklight.default_index.connection.get('database', params: { id: params[:id] })
    @db = @dbResponse['response']['docs']
  end

  def searchdb
    Appsignal.increment_counter('db_search_db', 1)
    if params[:q].blank? || params[:q] == "+" || params[:q] == "-"
      flash.now[:error] = "Please enter a query."
      render "index"
    else
      params[:q].gsub!('OR OR', 'OR')
      params[:q].gsub!('AND AND', 'AND')
      response = Blacklight.default_index.connection.get('databases', params: { q: params[:q], defType: 'edismax' })
      @dbResponse = response['response']['docs']
      params[:q].gsub!('%20', ' ')
    end
  end

  # ============================================================================
  # Build TOU from database by Solr document id
  # ----------------------------------------------------------------------------
  def tou
    service = TouLookupService.new
    r = service.resolve_for_database_tou(id: params[:id])

    @db                = r[:db_docs]
    @ermDBResult       = r[:erm_records]
    @defaultRightsText = r[:default_rights_text]
    @column_names      = r[:columns]
  end

  # ============================================================================
  # Build 'New TOU' by executing both FOLIO licenses and Database TOU lookups
  # ----------------------------------------------------------------------------
  def new_tou
    service = TouLookupService.new(session: session)
    r = service.resolve_new_tou(title_id: params[:title_id], id: params[:id])

    @newTouResult      = r[:new_tou_result]
    @db                = r[:db_docs]
    @ermDBResult       = r[:erm_records]
    @defaultRightsText = r[:default_rights_text]
    @column_names      = r[:columns]
  end


  def erm_update
     Databases.update
  end
end
