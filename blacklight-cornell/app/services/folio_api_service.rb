class FolioApiService
  # ============================================================================
  # Service initializer. Accepts the Rails session so the service can read/write
  # the FOLIO token without depending on controller context directly.
  # ----------------------------------------------------------------------------
  def initialize(session:)
    @session = session
  end
  private :initialize

  # ============================================================================
  # Build Terms-of-Use data for a given eHoldings title_id by:
  # ----------------------------------------------------------------------------
  def get_folio_terms_of_use(title_id)
    result = []
    record = eholdings_record(title_id)
    return result unless record

    Array(record["included"]).each do |pkg|
      attrs = pkg.is_a?(Hash) ? pkg["attributes"] : nil
      next unless attrs&.dig("isSelected") == true

      package_id   = attrs["packageId"]
      package_name = attrs["packageName"]
      next if package_id.blank?

      sa = subscription_agreements(package_id)
      next unless sa.is_a?(Array) && sa.first

      remote_id = sa.dig(0, "linkedLicenses", 0, "remoteId")
      next if remote_id.blank?

      lic = license(remote_id)
      next unless lic.is_a?(Hash)

      lic["packageName"] = package_name
      result << lic unless result.any? { |h| h["id"] == lic["id"] }
    end

    result
  end


  private
  # ============================================================================
  # eholdings title JSON response described here:
  # https://s3.amazonaws.com/foliodocs/api/mod-kb-ebsco-java/r/titles.html#eholdings_titles_get
  # ----------------------------------------------------------------------------
  def eholdings_record(id)
    folio_request("#{ENV['OKAPI_URL']}/eholdings/titles/#{id}?include=resources")
  end

  # ============================================================================
  # Given a URL, make a FOLIO request and return the results
  # (or nil in case of a RestClient exception).
  # ----------------------------------------------------------------------------
  def folio_request(url)
    token = folio_token
    if url && token
      headers = {
        'X-Okapi-Tenant' => ENV['OKAPI_TENANT'],
        'x-okapi-token' => token,
        :accept => 'application/json, application/vnd.api+json'
      }
      response = RestClient.get(url, headers)
      JSON.parse(response.body) if response && response.code == 200
    end
  rescue RestClient::ExceptionWithResponse => err
    Rails.logger.error "TOU: Error making FOLIO request (#{err})"
    nil
  end


  # ============================================================================
  # Return a FOLIO authentication token for API calls -- either from the session if a token
  # was prevoiusly created, or directly from FOLIO otherwise.
  #
  # TODO: Caching is being disabled for now, since it's causing problems with the new expiring
  # token mechanism in FOLIO. We need to figure out how to cache the token properly. (mjc12)
  # ----------------------------------------------------------------------------
  def folio_token
    #  if session[:folio_token].nil?
    url = ENV['OKAPI_URL']
    tenant = ENV['OKAPI_TENANT']
    response = CUL::FOLIO::Edge.authenticate(url, tenant, ENV['OKAPI_USER'], ENV['OKAPI_PW'])
    if response[:code] >= 300
      Rails.logger.error "TOU error: Could not create a FOLIO token for #{user}"
    else
      @session[:folio_token] = response[:token]
    end
    #  end
    @session[:folio_token]
  end


  # ============================================================================
  # Make a FOLIO request to retrieve an array of subscription agreements linked
  # to an e-holdings record specified by id.
  # ----------------------------------------------------------------------------
  def subscription_agreements(id)
    folio_request("#{ENV['OKAPI_URL']}/erm/sas?filters=items.reference=#{id}&sort=startDate:desc")
  end


  # ============================================================================
  # Make a FOLIO request to retrieve a license object linked to an e-holdings
  # record specified by id ('remoteId' in the JSON).
  # ----------------------------------------------------------------------------
  def license(id)
    folio_request("#{ENV['OKAPI_URL']}/licenses/licenses/#{id}")
  end

end