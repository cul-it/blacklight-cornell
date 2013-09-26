module BlacklightCornellRequests

  class VoyagerRequest

    # Most of this code is by Rick Silterra, es287

    require 'nokogiri'


    HOLDINGS_URL = "http://catalog.library.cornell.edu:7074/vxws/GetHoldingsService"
    REQUEST_URL = "http://catalog.library.cornell.edu:7074/vxws/SendPatronRequestService"
    NETID_URL = "http://catalog.library.cornell.edu/cgi-bin/netid7.cgi"
    DB_ID     = '1@CORNELLDB20021226150546'
    COOKIE_STORE = "/tmp/cookies/holding_cookies.dat"

    attr_reader   :bibid
    attr_accessor :results, :lastname, :barcode, :patronid, :mtype, :itemid,:mfhdid,
                  :netid,:libraryid,:reqnna,:reqcomments,:req

    def initialize(bibid, args = {})
      @bibid = bibid
      @results = {}

      @http_client = args[:http_client]
      
      @holdings_url = args[:holdings_url]
      if @holdings_url.blank?
        @holdings_url = HOLDINGS_URL
      end
      
      @request_url = args[:request_url]
      if @request_url.blank?
        @request_url = REQUEST_URL
      end
    end

    def to_s
      "netid:#{@netid} lastname:#{@lastname} patronid:#{@patronid} "+
      "bibid:#{@bibid} #{@itemid}"+ 
      "response:#{@mtype} req:#{@req} result:#{@results}" ;
    end

    def patron(netid)
      http_client do |hc|
        begin
          res = hc.get_content(NETID_URL,:netid=> netid)
          pat = JSON.parse(res)
          @barcode  = pat['bc'] 
          @lastname = pat['last'] 
          @patronid = pat['pid'] 
          @pdata = pat 
          @netid = netid
        rescue
          @results= Hash.arbitrary_depth
          return self
        end
      end
    end

    def place_hold_title!
      req = hold_text_item
      place_any!(req)
    end

    def place_hold_item!
      req = hold_text_item
      place_any!(req)
    end

    def place_recall_title!
      req = recall_text_item
      place_any!(req)
    end

    def place_recall_item!
      req = recall_text_item
      place_any!(req)
    end

    def place_callslip_title!
      req = callslip_text_item
      place_any!(req)
    end

    def place_callslip_item!
      req = callslip_text_item
      place_any!(req)
    end

    def fetch_from_opac!
      raw_data = Hash.arbitrary_depth

      http_client do |hc|
        begin
          xml = Nokogiri::XML(hc.get_content(@holdings_url, :bibId => bibid))
        rescue
          @results= Hash.arbitrary_depth
          return self
        end
        get_content = lambda { |node| node ? node.content : nil }
        
        xml.root.add_namespace_definition("hol", "http://www.endinfosys.com/Voyager/holdings")
        xml.root.add_namespace_definition("mfhd", "http://www.endinfosys.com/Voyager/mfhd")
        xml.root.add_namespace_definition("item", "http://www.endinfosys.com/Voyager/item")

        xml.css("mfhd|mfhdRecord").collect do |holding|
          holding_id = holding.attributes["mfhdId"].value
          holding_hash = raw_data["holdings"][holding_id]

          holding_hash["call_number"] = holding.css("mfhd|mfhdData[name='callNumber']").collect(&:content).first
          holding_hash["location_name"] = holding.css("mfhd|mfhdData[name='locationDisplayName']").collect(&:content).first
          holding_hash["location_code"] = holding.css("mfhd|mfhdData[name='locationCode']").collect(&:content).first

          items = holding.css("mfhd|itemCollection").collect do |record|
            result = {}

            if record.at_css("item|itemData[name='statusCode']")
              result["code"] = get_content.call(record.at_css("item|itemData[name='statusCode']"))
              result["date"] = get_content.call(record.at_css("item|itemData[name='statusDate']"))
              result["tempLocation"] = get_content.call(record.at_css("item|itemLocationData[name='tempLocation']"))
            else
              result["code"] = "noitem"
            end

            result
          end

          holding_hash["items"] = items
        end

      end

      raw_data["status"] = true 
      parse_raw_data!(raw_data)

      return self
    end

    def parse_raw_data!(raw_data)
      statuses = ["not_available", "checked_out", "non_circulating", "available"]
      raw_data["holdings"].each_pair do |holding_id, holding|
        holding["items"].each do |item|
          case  item["code"]
          when "1"
            item["desc"] = "Available"
            item["status"] = "available"
          when "2"
            item["desc"] = "Checked out, due #{Date.parse(item["date"]).to_formatted_s(:short)}"
            item["status"] = "checked_out"
          when "noitem"
            item["desc"] = "Does not circulate"
            item["status"] = "non_circulating"
          else
            item["desc"] = "Unavailable"
            item["status"] = "not_available"
          end
        end

        holding["status"] = statuses[holding["items"].collect { |i| statuses.index(i["status"]).to_i }.max.to_i]  
     
      end

      @results = raw_data

    end

    def to_format(format = :object)
      case format
      when :json
        self.results.to_json

      when :hash
        self.results

      else
        self
      end
    end

    def self.fetch(*bibids)
      results = {}
      bibids.each do |id|
        results[id] = VoyagerRequest.new(id).fetch_from_opac!.results
      end
      results
    end

  private

    def place_any!(text)
      raw_data = Hash.arbitrary_depth
      @req = text

      begin
        bad_doc = Nokogiri::XML(text) { |config| config.strict }
      rescue Nokogiri::XML::SyntaxError => e
        self.mtype =  "syntax error in request: #{e} #{@req}"
        return [self.mtype]
      end

      self.mtype = 'initialized'

      http_client do |hc|
        begin
         # res = hc.request('POST', Rails.configuration.voyager_request_url,body:@req)
         res = hc.request('POST', @request_url, body:@req)
          xml = Nokogiri::XML(res.content())
          self.mtype = 'parsed'
        rescue
          @results= Hash.arbitrary_depth
          self.mtype =  xml.inspect#'failed'
          return self
        end
        @results = res.content();
        xml.root.add_namespace_definition("ser", "http://www.endinfosys.com/Voyager/serviceParameters")
        xml.xpath("//ser:message").collect do |m|
          self.mtype = m.attributes["type"].value
        end
       end
    end
  
     def callslip_text_item
      req = hold_text_item
      req.gsub!('HOLD','CALLSLIP')
    end

    def recall_text_item
      req = hold_text_item
      req.gsub!('HOLD','RECALL')
    end

    def http_client
      if @http_client 
        yield @http_client
      else
        VoyagerRequest.http_client_with_cookies do |hc|
          yield hc
        end
      end
    end

    def self.http_client_with_cookies
      hc = HTTPClient.new

      cookie_directory = File.dirname(COOKIE_STORE)
      Dir.mkdir(cookie_directory) unless Dir.exists?(cookie_directory)

      hc.set_cookie_store(COOKIE_STORE)
      yield hc
      hc.cookie_manager.save_all_cookies(true)
    end

    def hold_text_item
     req  = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
    <ser:serviceParameters xmlns:ser="http://www.endinfosys.com/Voyager/serviceParameters">
    <ser:parameters>
    <ser:parameter key="bibDbName">
      <ser:value>dev71ncdb - SysAdmin db def name</ser:value>
    </ser:parameter>
    <ser:parameter key="REQNNA">
      <ser:value>#{reqnna}</ser:value>
    </ser:parameter>
    <ser:parameter key="bibDbCode">
      <ser:value>LOCAL</ser:value>
    </ser:parameter>
    <ser:parameter key="requestCode">
      <ser:value>HOLD</ser:value>
    </ser:parameter>
    <ser:parameter key="CVAL">
      <ser:value>thisCopy</ser:value>
    </ser:parameter>
    <ser:parameter key="requestSiteId">
      <ser:value>#{DB_ID}</ser:value>
    </ser:parameter>
    <ser:parameter key='PICK'>
      <ser:value>#{libraryid}</ser:value>
    </ser:parameter>
    <ser:parameter key="bibId">
      <ser:value>#{bibid}</ser:value>
    </ser:parameter>
    <ser:parameter key="mfhdId">
      <ser:value>#{mfhdid}</ser:value>
    </ser:parameter>
    <ser:parameter key="itemId">
      <ser:value>#{itemid}</ser:value>
    </ser:parameter>
    <ser:parameter key="REQCOMMENTS">
      <ser:value>#{reqcomments}</ser:value>
    </ser:parameter>
    </ser:parameters>
    <ser:patronIdentifier patronId="#{patronid}" lastName="#{lastname}" patronHomeUbId="#{DB_ID}">
        <ser:authFactor type="B">#{barcode}</ser:authFactor>
    </ser:patronIdentifier>
    </ser:serviceParameters>
EOS
    end

  end


end
