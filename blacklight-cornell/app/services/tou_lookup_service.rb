########################################################################################################################
##  Process TOU requests for Folio and Solr  ###################################
################################################################################
class TouLookupService
  def initialize(
    solr: Blacklight.default_index.connection,
    erm_model: ::Erm_data,
    logger: Rails.logger,
    session: nil,
    token_provider: nil
  )
    @solr           = solr
    @erm_model      = erm_model
    @logger         = logger
    @token_provider = token_provider || FolioTokenProvider.new(session: session, logger: logger)
  end

  # ============================================================================
  # Builds the "new TOU" payload with FOLIO licenses plus database TOU fallbacks
  # ----------------------------------------------------------------------------
  def resolve_new_tou(title_id:, id:)
    new_tou_result = []
    record         = eholdings_record(title_id) || {}
    included       = record.is_a?(Hash) ? record['included'] : nil

    if included.present?
      included.each do |package|
        attrs = package['attributes'] rescue nil
        next unless attrs && attrs['isSelected'] == true

        package_id   = attrs['packageId']
        package_name = attrs['packageName']
        sas          = subscription_agreements(package_id)
        next unless sas.present? && sas[0].is_a?(Hash)

        first_link = Array(sas[0]['linkedLicenses']).first
        next unless first_link && first_link['remoteId']

        lic = license(first_link['remoteId'])
        next unless lic

        lic['packageName'] = package_name
        new_tou_result << lic unless new_tou_result.any? { |h| h['id'] == lic['id'] }
      end
    end

    db_part = resolve_for_database(id: id)

    {
      new_tou_result: new_tou_result,
      db_docs: db_part[:db_docs],
      erm_records: db_part[:erm_records],
      default_rights_text: db_part[:default_rights_text],
      columns: db_part[:columns]
    }
  rescue => e
    @logger.error("TOU: resolve_new_tou error for title_id=#{title_id} id=#{id}: #{e}")
    {
      new_tou_result: [],
      db_docs: [],
      erm_records: [],
      default_rights_text: '',
      columns: @erm_model.column_names.map(&:to_sym)
    }
  end
  # ============================================================================
  # Fetches an e-holdings title record (with resources included) from FOLIO.
  # eholdings title JSON response described here:
  # https://s3.amazonaws.com/foliodocs/api/mod-kb-ebsco-java/r/titles.html#eholdings_titles_get
  # ----------------------------------------------------------------------------
  def eholdings_record(title_id)
    folio_request("#{ENV['OKAPI_URL']}/eholdings/titles/#{title_id}?include=resources")
  end

  # =========================================================
  # Make a FOLIO request to retrieve an array of subscription
  # agreements linked to an e-holdings record specified by id
  # ---------------------------------------------------------
  def subscription_agreements(package_id)
    folio_request("#{ENV['OKAPI_URL']}/erm/sas?filters=items.reference=#{package_id}&sort=startDate:desc")
  end

  # =========================================================================
  # Make a FOLIO request to retrieve a license object linked to an e-holdings
  # record specified by 'remoteId' in the JSON
  # -------------------------------------------------------------------------
  def license(remote_id)
    folio_request("#{ENV['OKAPI_URL']}/licenses/licenses/#{remote_id}")
  end

  # ========================================================
  # Given a URL, make a FOLIO request and return the results
  # (or nil in case of a RestClient exception)
  # --------------------------------------------------------
  def folio_request(url)
    tok = @token_provider.fetch
    return nil unless url && tok

    headers = {
      'X-Okapi-Tenant' => ENV['OKAPI_TENANT'],
      'x-okapi-token'  => tok,
      accept: 'application/json, application/vnd.api+json'
    }

    resp = RestClient.get(url, headers)
    return JSON.parse(resp.body) if resp && resp.code == 200

    nil
  rescue RestClient::Unauthorized
    @logger.info 'TOU: 401 from Okapi; invalidating token and retrying once'
    @token_provider.invalidate
    tok = @token_provider.fetch
    return nil unless tok

    headers = {
      'X-Okapi-Tenant' => ENV['OKAPI_TENANT'],
      'x-okapi-token'  => tok,
      accept: 'application/json, application/vnd.api+json'
    }
    resp = RestClient.get(url, headers)
    JSON.parse(resp.body) if resp && resp.code == 200
  rescue RestClient::ExceptionWithResponse => err
    @logger.error "TOU: FOLIO request error (#{err}) for #{url}"
    nil
  end

  # ==============================================================
  # Resolve TOU using the "database" core by ID.
  # Extracts db/provider codes and queries Erm_data with fallbacks
  # --------------------------------------------------------------
  def resolve_for_database(id:)
    increment_metric('db_tou')

    db_docs = solr_get('database', id: id).dig('response', 'docs') || []
    return build_result([], [], 'DatabaseCode and ProviderCode returns nothing') if db_docs.empty?

    doc = db_docs.first
    dbcode, providercode = pull_db_and_provider_codes(doc)

    if dbcode.blank?
      json = safe_parse_first_url_access_json(doc)
      return build_result(db_docs, [], 'Use default rights text') if json.nil?

      providercode = first_or_self(json['providercode'])
      return build_result(db_docs, [], 'Use default rights text') if providercode.blank?

      dbcode = json['dbcode']
      erm_records, default_text = query_erm_with_fallbacks(dbcode: dbcode, providercode: providercode)
      build_result(db_docs, erm_records, default_text)
    else
      providercode = first_or_self(providercode)
      erm_records, default_text = query_erm_with_fallbacks(dbcode: dbcode, providercode: providercode)
      build_result(db_docs, erm_records, default_text)
    end
  end

  # ============================================================
  # Resolve Terms of Use for CatalogController (termsOfUse path)
  # ------------------------------------------------------------
  def resolve_catalog_terms_of_use(id:, dbcode:, providercode:)
    db_response = solr_get('termsOfUse', id: id)
    num_found   = db_response.dig('response', 'numFound').to_i

    if num_found.zero?
      return {
        db_response: db_response,
        db: nil,
        db_response2: nil,
        db2: nil,
        dblinks: [],
        erm_records: [],
        default_text: '',
        columns: @erm_model.column_names.map(&:to_sym)
      }
    end

    db_doc    = db_response.dig('response', 'docs', 0)
    dblinks   = Array(db_doc.to_h['url_access_json'])
    db        = db_doc
    erm_recs  = []
    default   = ''

    dblinks.each do |link_str|
      l = safe_json(link_str)
      next unless l

      db = [l]

      link_provider = first_or_self(l['providercode'])
      link_dbcode   = l['dbcode']

      if link_provider.to_s.strip == providercode.to_s.strip && link_dbcode.to_s.strip == dbcode.to_s.strip
        default = ''
        erm_recs, default = query_erm_for_terms_link(l)
        break
      end
    end

    db_response2 = solr_get('select', qt: 'search', fl: '*', q: "id:#{id}")
    db2          = db_response2.dig('response', 'docs', 0)

    {
      db_response: db_response,
      db: db,
      db_response2: db_response2,
      db2: db2,
      dblinks: dblinks,
      erm_records: erm_recs,
      default_text: default,
      columns: @erm_model.column_names.map(&:to_sym)
    }
  end


  ######################################################################################################################
  ##  Provides cached FOLIO token management using the Rails session.  #########
  ##############################################################################
  class FolioTokenProvider
    def initialize(session:, logger: Rails.logger)
      @session = session
      @logger  = logger
    end

    # ====================================================================
    # Returns a valid FOLIO token, caching it in the session when possible
    # --------------------------------------------------------------------
    def fetch
      if @session
        current_session_token = @session[:folio_token]
        session_token_exp     = @session[:folio_token_expires_at]
        current_time          = Time.now.to_i
        return current_session_token if current_session_token && session_token_exp && session_token_exp > current_time
      end

      url    = ENV['OKAPI_URL']
      tenant = ENV['OKAPI_TENANT']
      resp   = CUL::FOLIO::Edge.authenticate(url, tenant, ENV['OKAPI_USER'], ENV['OKAPI_PW'])

      if resp[:code].to_i >= 300
        @logger.error "FolioTokenProvider: auth failed (code=#{resp[:code]})"
        return nil
      end

      token      = resp[:token]
      ttl_secs   = Integer(ENV.fetch('FOLIO_TOKEN_TTL_SECONDS', 45 * 60)) rescue 2700
      expires_at = Time.now.to_i + ttl_secs

      if @session
        @session[:folio_token]            = token
        @session[:folio_token_expires_at] = expires_at
      end

      token
    end

    # ===============================================================
    # Deletes any cached token so the next fetch will re-authenticate
    # ---------------------------------------------------------------
    def invalidate
      return unless @session

      @session.delete(:folio_token)
      @session.delete(:folio_token_expires_at)
    end
  end


  ######################################################################################################################
  ##  Private Methods  #########################################################
  ##############################################################################
  private

  # ===================================
  # Solr GET wrapper with error capture
  # -----------------------------------
  def solr_get(path, params = {})
    @solr.get(path, params: params)
  rescue => e
    @logger.error("TOU: Solr GET error at #{path} with #{params.inspect}: #{e}")
    {}
  end

  # ==========================================================================
  # Pull dbcode/providercode from a database doc, handling arrays/blank values
  # --------------------------------------------------------------------------
  def pull_db_and_provider_codes(doc)
    dbcode       = doc['dbcode']
    providercode = first_or_self(doc['providercode'])
    [dbcode, providercode]
  end

  # ============================================================================
  # Safely parse the first url_access_json entry if present; returns Hash or nil
  # ----------------------------------------------------------------------------
  def safe_parse_first_url_access_json(doc)
    arr = doc['url_access_json']
    return nil unless arr.is_a?(Array) && arr.first.present?

    safe_json(arr.first)
  end

  # =======================
  # JSON.parse with rescue
  # -----------------------
  def safe_json(str)
    JSON.parse(str)
  rescue JSON::ParserError
    nil
  end

  # =================================
  # Erm fallbacks for "database" path
  # ---------------------------------
  def query_erm_with_fallbacks(dbcode:, providercode:)
    records = @erm_model.where(Database_Code: dbcode, Provider_Code: providercode, Prevailing: 'true')
    if records.empty?
      records = @erm_model.where(Database_Code: ['', nil], Provider_Code: providercode, Prevailing: 'true')
      return [[], 'DatabaseCode and ProviderCode returns nothing'] if records.empty?
    end
    [records, '']
  end

  # ========================================================================
  # Erm fallbacks for "termsOfUse" path (SSID-aware), descending specificity
  # ------------------------------------------------------------------------
  def query_erm_for_terms_link(link_hash)
    pc  = first_or_self(link_hash['providercode'])
    dbc = link_hash['dbcode']
    ss  = link_hash['ssid']

    records = @erm_model.where(SSID: ss, Provider_Code: pc, Database_Code: dbc, Prevailing: 'true')
    return [records, ''] if records.present?

    records = @erm_model.where(SSID: ss, Provider_Code: pc, Prevailing: 'true')
    return [records, ''] if records.present?

    records = @erm_model.where(Database_Code: dbc, Provider_Code: pc, Prevailing: 'true')
    return [records, ''] if records.present?

    records = @erm_model.where(Provider_Code: pc, Prevailing: 'true', Database_Code: '')
    return [records, ''] if records.present?

    [[], 'Use default rights text']
  end

  # ==================================================
  # Normalize provider codes that can arrive as Arrays
  # --------------------------------------------------
  def first_or_self(value)
    value.is_a?(Array) ? value.first : value
  end

  # ==========================================================================
  # Constructs a controller-friendly result hash. Avoid mutating frozen arrays
  # --------------------------------------------------------------------------
  def build_result(db_docs, erm_records, default_text)
    {
      db_docs: db_docs,
      erm_records: erm_records,
      default_rights_text: default_text,
      columns: @erm_model.column_names.map(&:to_sym)
    }
  end

  # ========================================================================
  # Increment a counter safely without hard dependency on Appsignal presence
  # ------------------------------------------------------------------------
  def increment_metric(name)
    Appsignal.increment_counter(name, 1) if defined?(Appsignal)
  rescue => e
    @logger.debug("TOU: metric #{name} not incremented: #{e}")
  end
end
