module BlacklightCornellRequests

  class VoyagerRequest

    # Most of this code is by Rick Silterra, es287

    require 'nokogiri'


    HOLDINGS_URL = ENV['HOLDINGS_URL']
    REQUEST_URL = ENV['REQUEST_URL']
    NETID_URL = ENV['NETID_URL']
    COOKIE_STORE = ENV['COOKIE_STORE']
    DB     = ENV['VOYAGER_DB']
    DB_ID     = "1@#{DB}"
    REST_URL  = ENV['REST_URL']


    attr_reader   :bibid
    attr_accessor :results, :lastname, :barcode, :patronid, :mtype, :bcode, :itemid,:mfhdid,
                  :netid,:libraryid,:reqnna,:reqcomments,:req,:requests

    @@rest =  false 
     
    def initialize(bibid, args = {})
      @bibid = bibid
      @results = {}
      @requests = []

      @http_client = args[:http_client]
      
      @holdings_url = args[:holdings_url]
      if @holdings_url.blank?
        @holdings_url = HOLDINGS_URL
      end
      
      @request_url = args[:request_url]
      if @request_url.blank?
        @request_url = REQUEST_URL
      end
      @rest_url = args[:rest_url]
      if @rest_url.blank?
        @rest_url = REST_URL
      end
    end

    def to_s
      "netid:#{@netid} lastname:#{@lastname} patronid:#{@patronid} "+
      "bibid:#{@bibid} #{@itemid}"+ 
      "response:#{@mtype} req:#{@req} result:#{@results}" ;
    end

    def self.use_rest(rest) 
      ret = @@rest
      @@rest = rest
      ret 
    end

    def self.rest() 
      @@rest
    end
    
    def patron(netid)
      http_client do |hc|
        begin
          res = hc.get_content(NETID_URL,:netid=> netid)
          logger_info "Patron: #{res}\n "
          pat = JSON.parse(res)
          @barcode  = pat['bc'] 
          @lastname = pat['last'] 
          @patronid = pat['pid'] 
          @pdata = pat 
          @netid = netid
        rescue
          logger_info "Patron failed: #{netid}"
          @results= Hash.arbitrary_depth
          return self
        end
      end
    end

    def place_hold_item_rest!
      req = hold_text_item_rest
      place_any_rest!(req,'hold')
    end


# the docs do not actually describe how to do this.
    def place_hold_title!
      req = hold_text_item
      place_any!(req)
    end

    def place_hold_title!
      place_hold_title_rest!
    end

    def place_hold_title_rest!
      req = hold_text_title_rest
      place_any_rest!(req,'hold')
    end

    def place_hold_item!
      if (@@rest)
        place_hold_item_rest!
      else
        place_hold_item_xml!
      end
    end

    def place_hold_item_xml!
      req = hold_text_item
      place_any!(req)
    end

    def place_recall_title!
      req = recall_text_item
      place_any!(req)
    end

    def place_recall_title_rest!
      req = recall_text_title_rest
      place_any_rest!(req,'recall')
    end

    def place_recall_item!
      if (@@rest)
        place_recall_item_rest!
      else
        place_recall_item_xml!
      end
    end

    def place_recall_item_rest!
      req = recall_text_item_rest
      place_any_rest!(req,'recall')
    end

    def place_recall_item_xml!
      req = recall_text_item
      place_any!(req)
    end

    def place_callslip_title!
      req = callslip_text_title_rest
      place_any_rest!(req,'callslip')
    end

    def place_callslip_item!
      if (@@rest)
        place_callslip_item_rest!
      else
        place_callslip_item_xml!
      end
    end

    def place_callslip_item_xml!
      req = callslip_text_item
      place_any!(req)
    end

    def place_callslip_item_rest!
      req = callslip_text_item_rest
      place_any_rest!(req,'callslip')
    end

    def fetch_from_opac!
      raw_data = Hash.arbitrary_depth

      http_client do |hc|
        begin
          xml = Nokogiri::XML(hc.get_content(@holdings_url, :bibId => bibid))
          @xml = xml
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

  def user_account
          self.mtype = 'initialized'
          http_client do |hc|
            begin
               #http://server:port/vxws/MyAccountService?patronId=XXXX&patronHomeUbId=YYYY 
               myurl = @request_url+"?patronId=#{@patronid}&patronHomeUbId=#{DB_ID}"
               @req = myurl 
               res = hc.request('GET', @req)
               xml = Nokogiri::XML(res.content())
               @xml = xml 
               self.mtype = 'parsed'
             rescue
                @results= Hash.arbitrary_depth
                self.mtype =  xml.inspect#'failed'
                return self
             end
             @results = res.content();
             get_content = lambda { |node| node ? node.content : nil }
             xml.root.add_namespace_definition("vsd", "http://www.endinfosys.com/Voyager/serviceParameters")
             xml.root.add_namespace_definition("myac", "http://www.endinfosys.com/Voyager/myAccount")
            # <myac:requests>
            #<myac:title>Pending Requests</myac:title>
            #<myac:requestItem>
            #  <myac:itemID>42289</myac:itemID>
            #  <myac:holdRecallID>1491</myac:holdRecallID>
            #  <myac:replyNote/>
            #  <myac:status>1</myac:status>
            #  <myac:holdType>H</myac:holdType>
             xml.xpath("//myac:requests").collect do |m|
               m.xpath("myac:requestItem").collect do |r|
                 cass = get_content.call(r.at_xpath("myac:callslipStatus"))
                 ht   = get_content.call(r.at_xpath("myac:holdType"))
                 @requests <<  {:itemid => get_content.call(r.at_xpath("myac:itemID")),
                               :holdrecallid => get_content.call(r.at_xpath("myac:holdRecallID")),
                               :callslipstatus => cass,
                               :holdstatus => get_content.call(r.at_xpath("myac:status")),
                               :holdtype => ht
                              } unless (cass == '7' and ht == 'C')

             end
            end
          end
  end
  def cancel_recall_item!(holdid)
            cancel_any_item!('holds',holdid)
  end

  def cancel_hold_item!(holdid)
            cancel_any_item!('holds',holdid)
  end

  def cancel_callslip_item!(holdid)
            cancel_any_item!('callslips',holdid)
  end

  def cancel_any_item!(type,holdid)
          self.mtype = 'initialized'
          http_client do |hc|
            begin
               # res = hc.request('POST', Rails.configuration.voyager_request_url,body:@req)
               #cancsurl=  REST_URL+"/patron/#{patronid}/circulationActions/requests/#{type}/#{DB}%7C#{holdid}?patron_homedb=#{DB_ID}"
               #cancsurl=  "http://catalog-test.library.cornell.edu:7074" + "/patron/#{patronid}/circulationActions/requests/#{type}/#{DB}%7C#{holdid}?patron_homedb=#{DB_ID}"
               cancsurl = REST_URL + "/patron/#{patronid}/circulationActions/requests/#{type}/#{DB}%7C#{holdid}?patron_homedb=#{DB_ID}"
               res = hc.request('DELETE', cancsurl)
               xml = Nokogiri::XML(res.content())
               self.mtype = 'parsed'
             rescue
                @results= Hash.arbitrary_depth
                self.mtype =  xml.inspect#'failed'
                return self
             end
             @results = res.content();
             xml.xpath("//reply-text").collect do |m|
                @mtype = m.content == 'ok' ? 'success' : 'failure';
             end
             xml.xpath("//reply-code").collect do |m|
                @bcode = m.content
             end
            end
  end

  private

    def logger_info (text)
      if defined?(Rails) 
        Rails.logger.info  text
      else
        print text
     end
    end
       
    def place_any_rest!(text,type)

      raw_data = Hash.arbitrary_depth
      @req = text

      begin
        bad_doc = Nokogiri::XML(text) { |config| config.strict }
      rescue Nokogiri::XML::SyntaxError => e
        logger_info "Request (Failed): #{@req}"
        self.mtype =  "syntax error in request: #{e} #{@req}"
        return [self.mtype]
      end

      self.mtype = 'initialized'
      if itemid == ''
         rest_url = @rest_url  + "/record/#{bibid}/#{type}?patron=#{patronid}&patron_homedb=#{DB_ID}" 
      else
         rest_url = @rest_url  + "/record/#{bibid}/items/#{itemid}/#{type}?patron=#{patronid}&patron_homedb=#{DB_ID}" 
      end 
      #rest_url = @rest_url  + "/record/#{bibid}/items/#{itemid}/#{type}?patron=#{patronid}&patron_homedb=#{DB_ID}" 
        logger_info "Request rest url: #{rest_url}"
        logger_info "Request Body: #{@req}"
      http_client do |hc|
        begin
         # res = hc.request('POST', Rails.configuration.voyager_request_url,body:@req)
          res = hc.request('PUT', rest_url, body:@req)
          xml = Nokogiri::XML(res.content())
          self.mtype = 'parsed'
        rescue
          logger_info "Result (Failed): #{@req}"
          @results= Hash.arbitrary_depth
          self.mtype =  xml.inspect#'failed'
          return self
        end
        @results = res.content();
        logger_info "Result: #{res.content()}"
        xml.xpath("//reply-text").collect do |m|
          @mtype = m.content == 'ok' ? 'success' : 'failure';
        end
        xml.xpath("//reply-code").collect do |m|
          @bcode = m.content
          #if @bcode == '25'
          #   @bcode = '8'
          #   @mtype = 'blocked'
          #end
        end
      end
    end

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
          self.bcode = m.attributes.key?("blockCode") ? m.attributes["blockCode"].value : ''
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
        #VoyagerRequest.http_client_with_cookies do |hc|
        VoyagerRequest.http_client_without_cookies do |hc|
          yield hc
        end
      end
    end

    def self.http_client_without_cookies
      hc = HTTPClient.new
      yield hc
    end
    
    def self.http_client_with_cookies
      hc = HTTPClient.new

      cookie_directory = File.dirname(COOKIE_STORE)
      Dir.mkdir(cookie_directory) unless Dir.exists?(cookie_directory)

      hc.set_cookie_store(COOKIE_STORE)
      yield hc
      hc.cookie_manager.save_all_cookies(true)
    end

# this does not quite match the docs, but the docs do not make sense.
    def old_callslip_text_item_rest
    reqcom = reqcomments.blank? ? '' :
             reqcomments.encode(:xml=>:text)
    req = <<EOS 
<?xml version="1.0" encoding="UTF-8"?>
<call-slip-parameters>
<pickup-location>#{libraryid}</pickup-location>
<comment>#{reqcom}</comment>
<dbkey>#{DB_ID}</dbkey>
<reqinput field="1"></reqinput>
<reqinput field="2"></reqinput>
<reqinput field="3"></reqinput>
</call-slip-parameters>
EOS
    end 
    def callslip_text_title_rest
            "<?xml version='1.0' encoding='UTF-8'?>\n" +
           '<call-slip-title-parameters>' +
            text_callslip_parameters_rest +
           '</call-slip-title-parameters>' 
    end

    def callslip_text_item_rest
            "<?xml version='1.0' encoding='UTF-8'?>\n" +
           '<call-slip-parameters>' +
            text_callslip_parameters_rest +
           '</call-slip-parameters>' 
    end

    def text_callslip_parameters_rest
    reqcom = reqcomments.blank? ? '' :
             reqcomments.encode(:xml=>:text)
     req = <<EOS
<pickup-location>#{libraryid}</pickup-location>
<comment>#{reqcom}</comment>
<dbkey>#{DB_ID}</dbkey>
<reqinput field="1"></reqinput>
<reqinput field="2"></reqinput>
<reqinput field="3"></reqinput>
EOS
    end 

    def text_parameters_rest
    rest_reqnna = reqnna.gsub("-",'') 
    reqcom = reqcomments.blank? ? '' :
             reqcomments.encode(:xml=>:text)
      req = <<EOS 
        <pickup-location>#{libraryid}</pickup-location>
        <last-interest-date>#{rest_reqnna}</last-interest-date>
        <comment>#{reqcom}</comment>
        <dbkey>#{DB_ID}</dbkey>
EOS
    end

    def hold_text_title_rest
    "<?xml version='1.0' encoding='UTF-8'?>\n" +
           '<hold-title-parameters>' +
           text_parameters_rest +
           '</hold-title-parameters>'
    end 
 
    def hold_text_item_rest
    "<?xml version='1.0' encoding='UTF-8'?>\n" +
           '<hold-request-parameters>' +
           text_parameters_rest +
           '</hold-request-parameters>'
    end 

    def recall_text_item_rest
    "<?xml version='1.0' encoding='UTF-8'?>\n" +
           '<recall-parameters>' +
           text_parameters_rest +
           '</recall-parameters>'
    end 
    def recall_text_title_rest
    "<?xml version='1.0' encoding='UTF-8'?>\n" +
           '<recall-title-parameters>' +
           text_parameters_rest +
           '</recall-title-parameters>'
    end 
    def old_recall_text_item_rest
    rest_reqnna = reqnna.gsub("-",'') 
    reqcom = reqcomments.blank? ? '' :
             reqcomments.encode(:xml=>:text)
    req = <<EOS 
<?xml version="1.0" encoding="UTF-8"?>
<recall-parameters>
<pickup-location>#{libraryid}</pickup-location>
<last-interest-date>#{rest_reqnna}</last-interest-date>
<comment>#{reqcom}</comment>
<dbkey>#{DB_ID}</dbkey>
</recall-parameters>
EOS
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
