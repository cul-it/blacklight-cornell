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

  def tou
    Appsignal.increment_counter('db_tou', 1)
    response = Blacklight.default_index.connection.get('database', params: { id: params[:id] })
    @db = response['response']['docs']
    if !@db[0].nil?
      dbcode = @db[0]['dbcode']
      providercode = @db[0]['providercode']
      parsedpoop = ActiveSupport::JSON.decode(@db[0]['url_access_json'][0])
      @defaultRightsText = ''
      if dbcode.nil? or dbcode == '' #check for providerCode being nil
          #check url_access_json for values
          possibleprovidercode = ActiveSupport::JSON.decode(@db[0]['url_access_json'][0])['providercode']
          if possibleprovidercode.nil? or possibleprovidercode == ''
           @defaultRightsText = "Use default rights text"
          else
            providercode = possibleprovidercode
            dbcode = ActiveSupport::JSON.decode(@db[0]['url_access_json'][0])['dbcode']
            @ermDBResult = ::Erm_data.where(Database_Code: dbcode, Provider_Code: providercode, Prevailing: 'true')
            if @ermDBResult.size < 1
              #@ermDBResult = ::Erm_data.where("Provider_Code = :pvc AND Prevailing = 'true' AND (Database_Code =  '' OR Database_Code IS NULL)",pvc: providercode[0])
              @ermDBResult = ::Erm_data.where(Database_Code: ['',nil], Provider_Code: providercode, Prevailing: 'true')
              #@ermDBResult = ::Erm_data.where("Provider_Code = \'#{providercode[0]}\' AND Prevailing = 'true' AND (Database_Code =  '' OR Database_Code IS NULL)")

              # :nocov:
                Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} ermDBResult with no db code  = #{@ermDBResult.inspect}")
              # :nocov:

              if @ermDBResult.size < 1
                @defaultRightsText = "DatabaseCode and ProviderCode returns nothing"
              end
            end            
          end
      else
        @ermDBResult = ::Erm_data.where(Database_Code: dbcode, Provider_Code: providercode, Prevailing: 'true')

        if @ermDBResult.size < 1
          #@ermDBResult = ::Erm_data.where("Provider_Code = :pvc AND Prevailing = 'true' AND (Database_Code =  '' OR Database_Code IS NULL)",pvc: providercode[0])
          @ermDBResult = ::Erm_data.where(Database_Code: ['',nil], Provider_Code: providercode[0], Prevailing: 'true')
          #@ermDBResult = ::Erm_data.where("Provider_Code = \'#{providercode[0]}\' AND Prevailing = 'true' AND (Database_Code =  '' OR Database_Code IS NULL)")

          # :nocov:
            Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} ermDBResult with no db code  = #{@ermDBResult.inspect}")
          # :nocov:

          if @ermDBResult.size < 1
            @defaultRightsText = "DatabaseCode and ProviderCode returns nothing"
          end
        end
     end
   else
    @defaultRightsText = "DatabaseCode and ProviderCode returns nothing"
   end
   @column_names = ::Erm_data.column_names.collect(&:to_sym)

  end
 
  def erm_update
     Databases.update
  end

end
