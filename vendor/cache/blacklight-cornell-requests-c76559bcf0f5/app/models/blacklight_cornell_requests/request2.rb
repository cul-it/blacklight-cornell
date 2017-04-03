require 'benchmark'
require 'borrow_direct'
include BlacklightCornellRequests::Cornell::LDAP
include Blacklight::SolrHelper

module BlacklightCornellRequests
  # @author Matt Connolly

  class Request2
    
    attr_reader :bibid, 
                :netid, 
                :document,
                :work,
                # holdings_data is the unprocesssed data returned by a call to the holdings service 
                # @todo Do we really need to keep this around?
                :holdings_data,
                # holdings contains an array of Holding class instances for each library holding of
                # this bibid. 
                :holdings,
                # The particular volume requested, if any
                :bd_available,
                :multivolume
                
                
    attr_accessor :volume
    
    # Class-level constructor for building a request with test doc and holdings data
    # (to avoid the currently very expensive calls to external services while testing)
    def self.test_request(bibid, netid, bd)
      instance = allocate
      doc = hold = nil
      if bibid == 1419
        doc = JSON.parse(File.read('sampledoc1'), :symbolize_names => true)
        hold = JSON.parse(File.read('samplehold1'), :symbolize_names => false)
        puts doc[:isbn_display]
        puts doc[:title_display]
      elsif bibid == 1816041
        doc = JSON.parse(File.read('sampledoc2'), :symbolize_names => true)
        hold = JSON.parse(File.read('samplehold2'), :symbolize_names => false)
      else
        return nil
      end
      instance.send(:initialize, bibid, 'mjc12', doc, hold, bd)
      instance
    end
    
    # Basic initializer
    # 
    # @param bibid [Fixnum] The bibID being requested
    # @param netid [String] The Cornell NetID of the requester
    # @param document [Hash] The Solr documenta associated with the bibID
    # @param volume [Hash] The selected volume, if any. This is a hash of chron/enum/year
    # NOTE: it's possible to load the document directly by doing the following:
    #   1. include Blacklight::SolrHelper at the top of the file
    #   2. create a @blacklight_config instance variable
    #   3. set @blacklight_config to rc.blacklight_config, where rc is a RequestController instance
    #   4. call get_solr_response_for_doc_id as an instance method
    #   But since blacklight_config has to be copied from the controller anyway,
    # there's no real advantage to doing this over just passing in the document
    # as an initialization param.
    def initialize(bibid, netid, document, holdings_data = nil, bd = false, volume = {})
      @bibid = bibid
      @netid = netid
      @document = document
      @bd_available = bd || available_in_bd?
      @holdings_data = holdings_data || get_holdings
      @holdings = parse_holdings
      @work = Work.new(document, items())
      @volume = volume
      @multivolume = document[:multivol_b]
      set_item_docs    # Assign the appropriate chunk of the Solr document to each item record
      @pda_data = nil  # Patron-driven acquisition
    end
    
    def inspect
      puts "BibID #{@bibid} requested for '#{@netid}' (patron type: #{get_patron_type(@netid)})"
      bd_avail = (@bd_available ? 'IS' : 'is NOT')
      puts "Item #{bd_avail} available in Borrow Direct"
      puts "Requested volume: #{@volume}"
    #  puts "There are #{@holdings.count} holdings records (#{@holdings.each |h| { print h}})"
    end
    
    def times
      Benchmark.bm do |benchmark|
        benchmark.report do
          available_in_bd?
        end
        benchmark.report do
          get_holdings
        end
        benchmark.report do
          parse_holdings
        end
      end
    end
    
    # once the holdings (and thus item records) have been parsed, go back and set
    # each item record's solrdoc property to the correct snippet from the main Solr
    # document
    def set_item_docs
      # If this is a PDA item, there won't be item records to work with
      return unless @document['item_record_display'].present?
      
      items().each { |i| i.solrdoc = solr_doc_for_item(i.id) }
    end
    
    def solr_doc_for_item(item_id)      
      unless @solr_doc_items
        @solr_doc_items = @document['item_record_display'].map { |i| JSON.parse(i) }
      end
      
      @solr_doc_items.find { |i| i['item_id'] == item_id.to_s }
    end
    
    def get_holdings
      
      response = HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/status_short/#{@bibid}")
      response = JSON.parse(response).with_indifferent_access
      puts "response: #{response.inspect}"
      response[@bibid.to_s][@bibid.to_s][:records][0][:holdings]
      
    end
    
    def parse_holdings
      
      holdings = []
      mfhds = Hash.new {|h, k| h[k] = [] }
      # Each chunk of holdings_data looks like this: 
      #{"BIB_ID"=>1419, "MFHD_ID"=>5248430, "ITEM_ID"=>6782463, "ITEM_STATUS"=>1, "DISPLAY_CALL_NO"=>"Oversize HD205 1962 .S52 +", "LOCATION_ID"=>99, "LOCATION_CODE"=>"olin", "LOCATION_DISPLAY_NAME"=>"Olin Library", "OQUANTITY"=>nil, "ODATE"=>nil, "LINE_ITEM_STATUS"=>nil, "LINE_ITEM_ID"=>nil, "TEMP_LOCATION_DISPLAY_NAME"=>nil, "TEMP_LOCATION_CODE"=>nil, "TEMP_LOCATION_ID"=>0, "ITEM_STATUS_DATE"=>"2013-07-11T05:39:16-04:00", "PERM_LOCATION"=>99, "PERM_LOCATION_DISPLAY_NAME"=>"Olin Library", "PERM_LOCATION_CODE"=>"olin", "CURRENT_DUE_DATE"=>nil, "HOLDS_PLACED"=>0, "RECALLS_PLACED"=>0, "PO_TYPE"=>nil, "ITEM_ENUM"=>"v.2", "CHRON"=>nil}
      @holdings_data.each do |h|
        mfhds[h['MFHD_ID']] << h
      end
      
      mfhds.each do |k, v|
        holdings << BlacklightCornellRequests::Holding.new(v)
      end
    
      holdings
      
    end
    
    # Return an array of all associated item records (accessed via @holdings)
    def items
      result = []
      @holdings.each do |h|
        h.items.each do |i|
            result << i
        end
      end
      
      result
    end
    
    # Return an array of associated item records ONLY for the set volume (if any)
    def selected_items
      if @volume.empty? || @volume.all? { |k,v| v.nil? }
        items()
      else
        items().select { |i| i.enumeration && i.volume_match?(@volume) }
      end
    end
    
    # Return an array of all viable delivery methods. If use_volume is true,
    # the methods will only be calculated for selected_items. If false, then 
    # methods will be calculated for ALL the item records
    def delivery_methods(use_volume = true)
      result = []
      patron_type = get_patron_type(@netid)
      item_records = use_volume ? selected_items : items
      item_records.each do |i|
        result += i.delivery_methods(patron_type)
      end
      # Following line is needed for call to subclasses to not crash ... but why?
      BlacklightCornellRequests::DeliveryMethod
      
      result << BD if @bd_available
      result << PDA if @pda_data = PDA.pda_data(@document) # Yes, this is an assignment
      result << AskLibrarian    # You can always ask a librarian!
      
      # We only need unique delivery methods, sorted by delivery time (minimum time in range)
      result.uniq.sort { |a, b| a.time[0] <=> b.time[0] }
    end
    
    # Determine whether any copy is available
    def available?
      selected_items.any? { |i| i.status.present? && i.status[:code] == 1 }
    end
    
    # Determine Borrow Direct availability for an ISBN or title
    # params = { :isbn, :title }
    # ISBN is best, but title will work if ISBN isn't available.
    def available_in_bd?
      
      return false if @document.nil?
      
      isbn  = document[:isbn_display]
      title = document[:title_display]
    
      # Set up params for BorrowDirect gem
      BorrowDirect::Defaults.api_key = ENV['BORROW_DIRECT_TEST_API_KEY']
      BorrowDirect::Defaults.api_base = 'https://bdtest.relais-host.com/'
      BorrowDirect::Defaults.library_symbol = 'CORNELL'
      BorrowDirect::Defaults.find_item_patron_barcode = patron_barcode(@netid)
      BorrowDirect::Defaults.timeout = 30 # (seconds)
      # if api_base isn't specified, it defaults to BD test database
      if Rails.env.production?
        BorrowDirect::Defaults.api_base = BorrowDirect::Defaults::PRODUCTION_API_BASE
        BorrowDirect::Defaults.api_key = ENV['BORROW_DIRECT_PROD_API_KEY']
      end

      response = nil
      
      # This block can throw timeout errors if BD takes to long to respond
      begin
        if isbn.present?
          # Note: [*<variable>] gives us an array if we don't already have one,
          # which we need for the map.
          response = BorrowDirect::FindItem.new.find(:isbn => ([*isbn].map!{|i| i = i.clean_isbn}))
        elsif title.present?
          response = BorrowDirect::FindItem.new.find(:phrase => title)
        end

        return response.requestable?

      rescue Errno::ECONNREFUSED => e
        if ENV['ROUTE_EXCEPTIONS_TO_HIPCHAT'] == 'true'
          ExceptionNotifier.notify_exception(e)
        end
        Rails.logger.warn 'Requests: Borrow Direct connection was refused'
        Rails.logger.warn e.message
        Rails.logger.warn e.backtrace.inspect
        return false
      rescue BorrowDirect::HttpTimeoutError => e
        if ENV['ROUTE_EXCEPTIONS_TO_HIPCHAT'] == 'true'
          ExceptionNotifier.notify_exception(e)
        end
        Rails.logger.warn 'Requests: Borrow Direct check timed out'
        Rails.logger.warn e.message
        Rails.logger.warn e.backtrace.inspect
        return false
      rescue BorrowDirect::Error => e
        if ENV['ROUTE_EXCEPTIONS_TO_HIPCHAT'] == 'true'
          ExceptionNotifier.notify_exception(e)
        end
        Rails.logger.warn 'Requests: Borrow Direct gave error.'
        Rails.logger.warn e.message
        Rails.logger.warn e.backtrace.inspect
        Rails.logger.warn response.inspect 
        return false
      end
      
    end
    
    # Use the external netid lookup script to figure out the patron's barcode
    # (this might duplicate what's being done in the voyager_request patron method)
    def patron_barcode(netid)

      uri = URI.parse(ENV['NETID_URL'] + "?netid=#{netid}")
      response = Net::HTTP.get_response(uri)

      # Make sure that we got a real result. Unfortunately, the CGI doesn't
      # return a nice error code
      return nil if response.body.include? 'Software error'

      # Return the barcode
      JSON.parse(response.body)['bc']

    end
  
    
  end
end

class String
  def clean_isbn
    temp = self
    if self.index(' ')
      temp   = self[0,self.index(' ')]
    end
    temp =  temp.size == 10 ? temp : temp.gsub!(/[^0-9X]*/, '')
    temp =  temp.size == 13 ? temp : temp.gsub!(/[^0-9X]*/, '')
    temp
  end
end