# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class AeonController < ApplicationController
  layout 'aeon/index'
  include Blacklight::Catalog

  @ic = 0
  @bcc = 0
  @bibid = ''
  @title = ''
  @warning = ''

  def reading_room
    @url = 'www.google.com'
  end

  def index
    @url = 'www.google.com'
    @review_text = 'Keep this request saved in your account for later review.' \
    ' It will not be sent to library staff for fulfillment.'
  end

  def new_aeon_login; end

  # rewrite of monograph.php from voy-api.library.cornell.edu
  def reading_room_request
    set_rr_instance_variables
    set_rr_vars_from_document
    set_holdings_and_items
    set_messages
    session[:current_user_id] = 1
  end

  def scan_aeon
    set_scan_instance_variables
    set_scan_vars_from_document
    set_holdings_and_items
    set_messages
    session[:current_user_id] = 1
  end

  def set_rr_instance_variables
    @finding_aid = params[:finding] || ''
    @url = 'http://www.googles.com'
    @bibid = params[:id]
    @doctype = 'Manuscript'
    # @aeon_type = 'GenericRequestManuscript'
    @webreq = 'GenericRequestManuscript'
    # @this_sub = '' # this is the submitter, but the 'submitter' variable doesn't seem to be used anywhere else
    @the_loginurl = loginurl
  end

  def set_rr_vars_from_document
    _, @document = search_service.fetch(params[:id])
    # @bibdata = make_bibdata(@document)
    # @bibdata_string = @bibdata.to_s
    @title = @document['fulltitle_display']
    @author = @document['author_display']
    @re506 = @document['restrictions_display']&.first || ''
  end

  def set_holdings_and_items
    holdings_json_hash = Hash(JSON.parse(@document['holdings_json']))
    items_json_hash = @document['items_json'] ? Hash(JSON.parse(@document['items_json'])) : {}
    @ho = holdings(holdings_json_hash, items_json_hash)
  end

  def set_messages
    @disclaimer = 'Once your order is reviewed by our staff you will then be sent an invoice. ' \
    'Your invoice will include information on how to pay for your order. You must pre-pay; ' \
    'staff cannot fulfill your request until you pay the charges.'
    @schedule_text = 'Select a date to visit. Materials held on site are available immediately; ' \
    'off-site items require scheduling 2 business days in advance, as indicated above. ' \
    'Please be sure that you choose a date when we are ' \
    '<a href="https://www.library.cornell.edu/libraries/rmc">open</a>.'
    @review_text = 'Keep this request saved in your account for later review. ' \
    'It will not be sent to library staff for fulfillment.'
    @quest_text = 'Please email <a href=mailto:rareref@cornell.edu>rareref@cornell.edu</a> if you have any questions.'
  end

  def set_scan_instance_variables
    @finding_aid = params[:finding] || ''
    @url = 'http://www.googles.com'
    @bibid = params[:id]
    # @this_sub = ''
    # @cart = selecter # this is the submitter, but the 'submitter' variable doesn't seem to be used anywhere else
    @the_loginurl = loginurl

    # TODO: Do we really need 3 instance vars that all say the same thing?
    @doctype = 'Photoduplication'
    # @aeon_type = 'PhotoduplicationRequest'
    @type = 'PhotoduplicationRequest'
    @webreq = 'Copy'
  end

  def set_scan_vars_from_document
    _, @document = search_service.fetch(params[:id])
    # @bibdata = make_bibdata(@document)
    @title = @document['fulltitle_display']
    @author = @document['author_display']
    @re506 = @document['restrictions_display']&.first&.delete_suffix("'") || ''
    @warning = warning(@title)
  end

  # def selecter
  #   '
  #     <div id="shoppingcart">
  #     <span id="numitems">Number of items selected:</span>
  #     <span id="num-selections-wrapper">
  #     <span id="num-selections">
  #     </span>
  #     </span>

  #     <div id="selections-wrapper">
  #     <ol><div id="selections"></div>
  #     </ol>
  #     </div>
  #     </div>
  #   '
  # end

  def loginurl
    '/aeon/aeon_login'
    # 	return "http://dev-jac2445.library.cornell.edu/aeon511/aeon-login.php"
    # 	return "http://voy-api.library.cornell.edu/aeon/aeon_test-login.php"
  end

  def warning(title)
    if title.include?('[electronic resource]')
      'There is an electronic version of this resource -- do you really want to request this?'
    else
      ''
    end
  end

  # def clearer
  #   '
  #     <div class="control-group">
  #     <label class="control-label sr-only" for="SubmitButton">Submit request</label>
  #     <input type="submit" class="btn btn-dark" id="SubmitButton" name="SubmitButton" value="Submit Request">
  #     <label class="control-label sr-only" for="clear">Clear</label>
  #     <input type="button" class="btn btn-secondary" id="clear"  name="clear" value="Clear Form">
  #     <br/>' + @quest_text + '<br/>
  #     </div>
  #   '
  # end

  # def former
  #   '</form>'
  # end

  # def submitter
  #   ''
  # end

  # def xsubmitter
  #   '
  #       <div class="control-group">
  #       <div class="controls">
  #       <label class="control-label sr-only" for="SubmitButton">Submit request</label>
  #       <input type="submit" class="btn" id="SubmitButton" name="SubmitButton" value="Submit Request">
  #       </div>
  #       </div>
  #   '
  # end

  def login
    'woops'
  end

  # redirect_shib is redefined later in the class.
  # def redirect_shib
  #   redirect_to 'https://rmc-aeon.library.cornell.edu'
  # end

  # NOTE: This function doesn't seem to do anything useful - it always returns a static string for bibdata_output_hash,
  # and that string doesn't appear to be used anywhere else in the code.
  # def make_bibdata(document)
  #   holding_id = ''
  #   publisher = document['publisher_display'][0] || ''
  #   pubdate = document['pub_date_display'][0] || ''
  #   pubplace = document['pubplace_display'][0] || ''
  #   holdings_json = Hash(JSON.parse(document['holdings_json']))

  #   firstkeyout = ''
  #   count = 0
  #   bibdata_output_hash = '{"items": [{"author":null,"title":null,"pub_place":null,"publisher":null,"publisher_date":null,"edition":null,"bib_format":null,"permlocation":null,"permlocationcode":null,"holdings":[]}]}'
  #   if !document['items_json'].nil?
  #     bibdata_hash = Hash(JSON.parse(document['items_json']))
  #     bibdata_hash.each do | firstKey, value |
  #       if count == 0
  #         firstkeyout = firstKey
  #         count = count + 1
  #         valueHash = Hash(value[0])
  #         # 	        bibdata_output_hash = bibdata_output_hash + firstkeyout + '":['
  #       end
  #     end
  #   end
  #   if firstkeyout != ''
  #     callnum = holdings_json[firstkeyout]['call']
  #   else
  #     callnum = ''
  #   end

  #   if !document['items_json'].nil?
  #     bibdata_hash.each do | key, value |
  #       #	if count == 0
  #       holding_id = key
  #       valueArray = value.to_a
  #       valueArray.each do | key, hold |
  #       valueHash = Hash(hold)
  #       keyout = Hash[key]
  #     end
  #   end
  # end

  # return bibdata_output_hash
  # end

  def holdings(holdings_json_hash, items_json_hash)
    valholding = []
    # TODO: This code doesn't make sense to me. Given a hash of the form
    # { holdings_id1 => [ {item1} ], holdings_id2 => [ {item2} ] },
    # this produces { holdings_id1 => [ {item1, item2} ], holdings_id2 => [ {item1, item2} ] }.
    # I see no good reason to combine all the items from all the holdings into a single array for
    # each holding, and then duplicate that array for each holding. But without doing that, the items are not displayed
    # correctly in the view. This should be revisited once I understand that cause and effect better.
    items_json_hash.each do |holding_id, items|
      items.each do |item|
        item['enum'] ||= ''
        valholding << item
      end
      items = valholding
      begin
        items.sort_by! { |e| e['enum'].scan(/\D+|\d+/).map { |x| x =~ /\d/ ? x.to_i : x } }
      rescue StandardError
        items.sort_by! { |k| k['enum'] }
      end
      items_json_hash[holding_id] = items
    end
    xholdings(holdings_json_hash, items_json_hash)
  end

  # TODO: This method is a monster. It definitely needs refactoring and cleanup, but that's a project in itself.
  def xholdings(holdings_hash, items_hash)
        ret = ''
        holding_id = ''
        count = 0
        if !items_hash.empty?
          items_hash.each_key do |key|
            if count < 1
              holding_id = key
              this_item_array = items_hash[holding_id]
              # thisitem_hash = Hash(JSON.parse(this_item_array[0]))
              c = ''
              b = ''
              d = ''
              if !this_item_array.nil? && !this_item_array.empty?
                this_item_array.each do |item_hash|
                  unless !item_hash['location']['code'].include?('rmc') && !item_hash['location']['code'].include?('rare')
                    b = item_hash['call'].to_s
                    if b.include?('Archives ')
                      b = b.gsub('Archives ','')
                    end
                    if item_hash["location"]["library"] == 'Library Annex'
                      item_hash["location"]["library"] = "ANNEX"
                    end
                    if !item_hash["copy"].nil?
                      c =  " c. " + item_hash["copy"].to_s
                      if !item_hash['enum'].nil? and !item_hash['enum'].empty?
                        c = c + " " + item_hash['enum']
                      elsif !item_hash['chron'].nil? and !item_hash['chron'].empty?
                        c = c + " " + item_hash['chron']
                      end
                      if !item_hash["caption"].nil?
                        c = c + " " + item_hash["caption"]
                      end
                    end
                    if !item_hash["caption"].nil?
                      d = " " + item_hash["caption"]
                    else
                      d = ''
                    end
                    if item_hash['enum'].nil?
                      item_hash['enum'] = ''
                    end
                    if holdings_hash[holding_id]["call"].nil?
                      holdings_hash[holding_id]["call"] = ''
                    end
                    if !item_hash["barcode"].nil?
                      restrictions = ""
                      if !item_hash["rmc"].nil?
                        if !item_hash["rmc"]["Restrictions"].nil?
                          restrictions = item_hash["rmc"]["Restrictions"]
                        else
                          restrictions = ''
                        end
                      else
                        if !item_hash["location"].nil?
                          item_hash["rmc"] = {}
                          item_hash["rmc"]["Vault location"] = item_hash["location"]["code"] + ' ' + item_hash["location"]["library"]
                        else
                          item_hash["rmc"] = {}
                          item_hash["rmc"]["Vault location"] = "Not in record"
                        end
                      end
                      if item_hash["location"]["name"].include?('Non-Circulating')
                        ret = ret + "<div><label for='" + item_hash["barcode"] + "' class='sr-only'>i" + item_hash["barcode"] + "</label><input class='ItemNo'  id='" + item_hash["barcode"] + "' name='" + item_hash["barcode"] + "' type='checkbox' VALUE='" + item_hash["barcode"] + "'>"
                        if item_hash["rmc"].nil?
                          ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div><script> itemdata["' + item_hash["barcode"] + '"] = { location:"' + item_hash["location"]["code"] + '",enumeration:"' + item_hash["enum"] + '",barcode:"' + item_hash["barcode"] + '",loc_code:"' + item_hash["location"]["code"] +'",chron:"",copy:"' + item_hash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item_hash["location"]["code"] + ' ' + item_hash["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + item_hash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                        else
                          if item_hash["rmc"]["Vault location"].nil?
                            ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div><script> itemdata["' + item_hash["barcode"] + '"] = { location:"' + item_hash["location"]["code"] + '",enumeration:"' + item_hash["enum"] + '",barcode:"' + item_hash["barcode"] + '",loc_code:"' + item_hash["location"]["code"] +'",chron:"",copy:"' + item_hash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item_hash["location"]["code"] + ' ' + item_hash["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + item_hash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                          else
                            # for requests to route into Awaiting Restriction Review, the cslocation needs both the vault and the building 
                            vault_location = item_hash["rmc"]["Vault location"]
                            location_code = item_hash["location"]["code"]
                            cslocation = vault_location.include?(location_code) ? vault_location : vault_location + ' ' + location_code
                            ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div><script> itemdata["' + item_hash["barcode"] + '"] = { location:"' + vault_location + '",enumeration:"' + item_hash["enum"] + '",barcode:"' + item_hash["barcode"] + '",loc_code:"' + vault_location +'",chron:"",copy:"' + item_hash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + cslocation + '",code:"rmc' +  '",callnumber:"' + item_hash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                          end
                        end
                      else
                        ret = ret + "<div><label for='" + item_hash["barcode"] + "' class='sr-only'>" + item_hash["barcode"] + "</label><input class='ItemNo'  id='" + item_hash["barcode"] + "' name='" + item_hash["barcode"] + "' type='checkbox' VALUE='" + item_hash["barcode"] + "'>"
                        if item_hash["rmc"]["Vault location"].nil?
                          ret = ret + " (Request in Advance) " + b + c + "  " + restrictions + '</div><script> itemdata["' + item_hash["barcode"] + '"] = { location:"' + item_hash["location"]["code"] + '",enumeration:"' + item_hash["enum"] + '",barcode:"' + item_hash["barcode"] + '",loc_code:"' + item_hash["location"]["code"] +'",chron:"",copy:"' + item_hash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item_hash["location"]["code"] + ' ' + item_hash["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + item_hash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                        else
                          ret = ret + " (Request in Advance) " + b + c  + " " + restrictions  +  '</div><script> itemdata["' + item_hash["barcode"] + '"] = { location:"' + item_hash["rmc"]["Vault location"] + '",enumeration:"' + item_hash["enum"] + '",barcode:"' + item_hash["barcode"] + '",loc_code:"' + item_hash["location"]["code"] +'",chron:"",copy:"' + item_hash["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + item_hash["rmc"]["Vault location"] + '",code:"' + item_hash['location']["code"] + '",callnumber:"' + item_hash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                        end
                      end
                    else
                      restrictions = ""
                      if !item_hash["rmc"].nil?
                        if !item_hash["rmc"]["Restrictions"].nil?
                          restrictions = item_hash["rmc"]["Restrictions"]
                        end
                      else
                        restrictions = ""
                      end
                      if item_hash["rmc"].nil?
                        item_hash["rmc"] = {}
                        if !item_hash["location"]['library'].nil?
                          item_hash['rmc']['Vault location'] = item_hash['location']['library']
                        else
                          item_hash["rmc"]["Vault location"] = "not in record"
                        end
                      end
                      if item_hash["rmc"]["Vault location"].nil?
                        item_hash["rmc"]["Vault location"] = ""
                      end
                      if item_hash["location"]["name"].include?('Non-Circulating')
                        # ret = item_hash["rmc"]["Vault location"]
                        if item_hash["call"].nil?
                          item_hash["call"] == ""
                        end
                        # THIS IS WHERE THE PROBLEM IS
                        ret = ret + "<div><label for='iid-" + item_hash["id"].to_s + "' class='sr-only'>iid-" + item_hash["id"].to_s + "</label><input class='ItemNo'  id='iid-" + item_hash["id"].to_s + "' name='iid-" + item_hash["id"].to_s + "' type='checkbox' VALUE='iid-" + item_hash["id"].to_s + "'>"
                        ret = ret + " (Available Immediately) " + b + c + " " + restrictions + '</div><script> itemdata["iid-' + item_hash["id"].to_s + '"] = { location:"' + item_hash["rmc"]["Vault location"] + '",enumeration:"' + item_hash["enum"] + '",barcode:"iid-' + item_hash["id"].to_s + '",loc_code:"' + item_hash["location"]["code"] +'",chron:"",copy:"' + item_hash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item_hash["location"]["code"] + ' ' + item_hash["rmc"]["Vault location"] + '",code:"' + item_hash['location']["code"] + '",callnumber:"' + item_hash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                      else
                        # ret = ret + item_hash["barcode"]
                        ret = ret + "<div><label for='iid-" + item_hash["id"].to_s + "' class='sr-only'>iid-" + item_hash["id"].to_s + "</label><input class='ItemNo'  id='iid-" + item_hash["id"].to_s + "' name='iid-" + item_hash["id"].to_s + "' type='checkbox' VALUE='iid-" + item_hash["id"].to_s + "'>"
                        ret = ret + " (Request in Advance) " + b + c + " " + restrictions + '</div><script> itemdata["iid-' + item_hash["id"].to_s + '"] = { location:"' + item_hash["rmc"]["Vault location"] + '",enumeration:"' + item_hash["enum"] + '",barcode:"iid-' + item_hash["id"].to_s + '",loc_code:"' + item_hash["location"]["code"] +'",chron:"",copy:"' + item_hash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item_hash["rmc"]["Vault location"] + '",code:"' + item_hash['location']["code"] + '",callnumber:"' + item_hash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                      end
                      d = ''
                    end #barcode else
                  end
                end #do end
              else #nil end
                items_hash = {}
                valArray = []
                enum = ''
                restrictions = ''
                if !@document["items_json"].nil?
                  count = 0
                  items_hash = JSON.parse(@document["items_json"])
                  items_hash.each do |key, value|
                    if count < 1
                      value.each do |val|
                      if val["location"]["library"] == 'Library Annex'
                        val["location"]["library"] = "ANNEX"
                      end
                      if !val["barcode"].nil?
                        restrictions = ""
                        if !val["rmc"].nil?
                          if !val["rmc"]["Restrictions"].nil?
                            restrictions = val["rmc"]["Restrictions"]
                          end
                        else
                          val["rmc"] = {}
                          #  val["rmc"]["Vault location"].nil?
                          val["rmc"]["Vault location"] = "not in record"
                        end
                        if val["enum"].nil?
                          enum = ""
                        else
                          enum = val["enum"]
                        end
                        if val["location"]["name"].include?('Non-Circulating') #or val["location"]["name"].include?('Olin Library')
                          #		ret = ret + val.inspect
                          ret = ret + "<div><label for='" + val["barcode"] + "' class='sr-only'>" + val["barcode"] + "</label><input class='ItemNo'  id='" + val["barcode"] + "' name='" + val["barcode"] + "' type='checkbox' VALUE='" + val["barcode"] + "'>"
                          if val["rmc"].nil?
                            ret = ret + " (Available Immediately) " + val["call"] + " c " +  val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                          else
                            if val["rmc"]["Vault location"].nil?
                              ret = ret + " (Available Immediately) " + val["call"] + " c" + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                            else
                              ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                            end
                          end
                        else
                          ret = ret + "<div><label for='" + val["barcode"] + "' class='sr-only'>" + val["barcode"] + "</label><input class='ItemNo'  id='" + val["barcode"] + "' name='" + val["barcode"] + "' type='checkbox' VALUE='" + val["barcode"] + "'>"
                          if val["rmc"]["Vault location"].nil?
                            ret = ret + " (Request in Advance) " + val["call"] + " c" + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                          else
                            ret = ret + " (Request in Advance) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions  +  '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                          end
                        end
                      else
                        restrictions = ''
                        if !val["rmc"].nil?
                          if !val["rmc"]["Restrictions"].nil?
                            restrictions = val["rmc"]["Restrictions"]
                          end
                        end
                        if val["location"]["name"].include?('Non-Circulating')
                          ret = ret + "<div><label for='iid-" + val["id"].to_s + "' class='sr-only'>iid-" + val["id"].to_s + "</label><input class='ItemNo'  id='iid-" + val["id"].to_s + "' name='iid-" + val["id"].to_s + "' type='checkbox' VALUE='iid-" + val["id"].to_s + "'>"
                          ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                        else
                          # ret = ret + item_hash["barcode"]
                          ret = ret + "<div><label for='iid-" + val["id"].to_s + "' class='sr-only'>iid-" + val["id"].to_s + "</label><input class='ItemNo'  id='iid-" + val["id"].to_s + "' name='iid-" + val["id"].to_s + "' type='checkbox' VALUE='iid-" + val["id"].to_s + "'>"
                          ret = ret + " (Requests in Advance) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                        end
                      end #barcode else
                    end
                    count = count + 1
                  end
                end
              end
            end
            count = count + 1
          end
        end # end of  items_hash.each do |key, value|
      else # if items_hash.empty
        items_hash = {}
        valArray = []
        enum = ''
        restrictions = ''
        if !holdings_hash.nil?
          count = 0
          items_hash = JSON.parse(@document["holdings_json"])
          #	ret = items_hash.inspect
          items_hash.each do |key, val|
          if count < 1
            #		value.each do |key, val|
            #		  ret = ret + val.inspect
            if !val["barcode"].nil?
              restrictions = ""
              if !val["rmc"].nil?
                if !val["rmc"]["Restrictions"].nil?
                  restrictions = val["rmc"]["Restrictions"]
                end
              else
                val["rmc"] = {}
                #  val["rmc"]["Vault location"].nil?
                val["rmc"]["Vault location"] = "not in record"
              end
              if val["enum"].nil?
                enum = ""
              end
              if val["location"]["name"].include?('Non-Circulating')
                ret = ret + "<div><label for='" + val["barcode"] + "' class='sr-only'>" + val["barcode"] + "</label><input class='ItemNo'  id='" + val["barcode"] + "' name='" + val["barcode"] + "' type='checkbox' VALUE='" + val["barcode"] + "'>"
                if val["rmc"].nil?
                  #		ret = ret + val["location"]["name"] + " (Available Immediately) " + val["call"] + " c " +  val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                  ret = ret + val["location"]["name"] + " (Available Immediately) " + val["call"] + " c " +  val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]["Vault location"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                else
                  if val["rmc"]["Vault location"].nil?
                    ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                  else
                    # ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                    ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]["Vault loation"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                  end
                end
              else
                # ret = ret + item_hash["barcode"]
                ret = ret + "<div><label for='" + val["barcode"] + "' class='sr-only'>" + val["barcode"] + "</label><input class='ItemNo'  id='" + val["barcode"] + "' name='" + val["barcode"] + "' type='checkbox' VALUE='" + val["barcode"] + "'>"
                ret = ret + " (Request in Advance) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions  +  '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
              end
              # ret = "baby"
            else
              restrictions = ''
              if !val["rmc"].nil?
                if !val["rmc"]["Restrictions"].nil?
                  restrictions = val["rmc"]["Restrictions"]
                end
              else
                val["rmc"] = {}
                #  val["rmc"]["Vault location"].nil?
                val["rmc"]["Vault location"] = "not in record"
              end
              #        ret = ret + val.inspect
              if val["location"]["name"].include?('Non-Circulating')
                ret = ret + "<div><label for='iid-" + val["hrid"].to_s + "' class='sr-only'>iid-" + val["hrid"].to_s + "</label><input class='ItemNo'  id='iid-" + val["hrid"].to_s + "' name='iid-" + val["hrid"].to_s + "' type='checkbox' VALUE='iid-" + val["hrid"].to_s + "'>"
                # ret = ret + val["location"]["library"] + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["hrid"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["hrid"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                ret = ret + val["location"]["library"] + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["hrid"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["hrid"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]["Vault location"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
              else
                # ret = ret + item_hash["barcode"]
                ret = ret + "<div><label for='iid-" + val["id"].to_s + "' class='sr-only'>iid-" + val["id"].to_s + "</label><input class='ItemNo'  id='iid-" + val["id"].to_s + "' name='iid-" + val["id"].to_s + "' type='checkbox' VALUE='iid-" + val["id"].to_s + "'>"
                # ret = ret + " (Requests in Advance) " + val["call"] + " " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                ret = ret + " (Requests in Advance) " + val["call"] + " " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]["Vault location"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
              end
            end #barcode else
            #		end
            count = count + 1
          end
        end
      end
    end #end of if items_hash.empty
    ret = ret + "<!--Producing menu with items no need to refetch data. ic=**$ic**\n -->"
    #   ret = @document["items_json"]
    return ret
  end

  def aeon_login
    params
  end

  def redirect_nonshib
    @outbound_params = params
  end

  def boom; end

  def redirect_shib
    #     @user = User.new()
    #    @session = Session.new()
    #     session.user = "jac244"
    #        uri = URI('https://rmc-aeon.library.cornell.edu/aeon/aeon.dll')
    #        res = Net::HTTP.get_response(uri)
    #       Rails.logger.info("COOOKIE = #{cookies.inspect}")
    #       Rails.logger.info("RESBODY= #{res.body if res.is_a?(Net::HTTPSuccess)}")
    #        response = HTTParty.get('https://rmc-aeon.library.cornell.edu/aeon/boom.html?target=https://catalog-folio-int.library.cornell.edu')
    #       Rails.logger.info("HTTPARTY = #{response}")
    #       Rails.logger.info("COOOKIE = #{cookies.inspect}")
    @outbound_params = params
  end
end
# rubocop:enable Metrics/ClassLength
