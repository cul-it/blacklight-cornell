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
  #   holdingID = ''
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
  #       holdingID = key
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
    # TODO: This code doesn't make sense to me. Given a hash of the form  { holdings_id1 => [ {item1} ], holdings_id2 => [ {item2} ] },
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
      rescue
        items.sort_by! { |k| k['enum']}
      end
      items_json_hash[holding_id]= items
    end
    xholdings(holdings_json_hash, items_json_hash)
  end

  # TODO: This method is a monster. It definitely needs refactoring and cleanup, but that's a project in itself.
  def xholdings(holdingsHash, itemsHash)
    ret = ''
    holdingID = ''
    count = 0
    if !itemsHash.empty?
      itemsHash.each do |key, _value|
        next unless count < 1

        holdingID = key
        thisItemArray = itemsHash[holdingID]
        #  	  thisItemHash = Hash(JSON.parse(thisItemArray[0]))
        c = ''
        b = ''
        d = ''

        if !thisItemArray.nil? and !thisItemArray.empty?
          thisItemArray.each do |itemHash|
            next if !itemHash['location']['code'].include?('rmc') and !itemHash['location']['code'].include?('rare')

            b = itemHash['call'].to_s
            b = b.gsub('Archives ', '') if b.include?('Archives ')
            itemHash['location']['library'] = 'ANNEX' if itemHash['location']['library'] == 'Library Annex'
            # stuffHash = Hash(JSON.parse(otherstuff))
            if !itemHash['copy'].nil? and !itemHash['enum'].nil?
              c = ' c. ' + itemHash['copy'].to_s + ' ' + itemHash['enum']
              c = c + ' ' + itemHash['caption'] unless itemHash['caption'].nil?
            end
            d = if !itemHash['caption'].nil?
                  ' ' + itemHash['caption']
                else
                  ''
                end
            itemHash['enum'] = '' if itemHash['enum'].nil?
            holdingsHash[holdingID]['call'] = '' if holdingsHash[holdingID]['call'].nil?
            if !itemHash['barcode'].nil?
              restrictions = ''
              if !itemHash['rmc'].nil?
                restrictions = if !itemHash['rmc']['Restrictions'].nil?
                                 itemHash['rmc']['Restrictions']
                               else
                                 ''
                               end
              elsif !itemHash['location'].nil?
                itemHash['rmc'] = {}
                itemHash['rmc']['Vault location'] =
                  itemHash['location']['code'] + ' ' + itemHash['location']['library']
              else
                itemHash['rmc'] = {}
                itemHash['rmc']['Vault location'] = 'Not in record'
              end
              if itemHash['location']['name'].include?('Non-Circulating')
                ret = ret + "<div><label for='" + itemHash['barcode'] + "' class='sr-only'>i" + itemHash['barcode'] + "</label><input class='ItemNo'  id='" + itemHash['barcode'] + "' name='" + itemHash['barcode'] + "' type='checkbox' VALUE='" + itemHash['barcode'] + "'>"
                if itemHash['rmc'].nil?
                  ret = ret + ' (Available Immediately) ' + b + c + ' ' + restrictions + '</div><script> itemdata["' + itemHash['barcode'] + '"] = { location:"' + itemHash['location']['code'] + '",enumeration:"' + itemHash['enum'] + '",barcode:"' + itemHash['barcode'] + '",loc_code:"' + itemHash['location']['code'] + '",chron:"",copy:"' + itemHash['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash['location']['code'] + ' ' + itemHash['location']['library'] + '",code:"rmc' + '",callnumber:"' + itemHash['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                elsif itemHash['rmc']['Vault location'].nil?
                  ret = ret + ' (Available Immediately) ' + b + c + ' ' + restrictions + '</div><script> itemdata["' + itemHash['barcode'] + '"] = { location:"' + itemHash['location']['code'] + '",enumeration:"' + itemHash['enum'] + '",barcode:"' + itemHash['barcode'] + '",loc_code:"' + itemHash['location']['code'] + '",chron:"",copy:"' + itemHash['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash['location']['code'] + ' ' + itemHash['location']['library'] + '",code:"rmc' + '",callnumber:"' + itemHash['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                else
                  ret = ret + ' (Available Immediately) ' + b + c + ' ' + restrictions + '</div><script> itemdata["' + itemHash['barcode'] + '"] = { location:"' + itemHash['rmc']['Vault location'] + '",enumeration:"' + itemHash['enum'] + '",barcode:"' + itemHash['barcode'] + '",loc_code:"' + itemHash['rmc']['Vault location'] + '",chron:"",copy:"' + itemHash['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash['rmc']['Vault location'] + '",code:"rmc' + '",callnumber:"' + itemHash['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                end
              else
                ret = ret + "<div><label for='" + itemHash['barcode'] + "' class='sr-only'>" + itemHash['barcode'] + "</label><input class='ItemNo'  id='" + itemHash['barcode'] + "' name='" + itemHash['barcode'] + "' type='checkbox' VALUE='" + itemHash['barcode'] + "'>"
                if itemHash['rmc']['Vault location'].nil?
                  ret = ret + ' (Request in Advance) ' + b + c + '  ' + restrictions + '</div><script> itemdata["' + itemHash['barcode'] + '"] = { location:"' + itemHash['location']['code'] + '",enumeration:"' + itemHash['enum'] + '",barcode:"' + itemHash['barcode'] + '",loc_code:"' + itemHash['location']['code'] + '",chron:"",copy:"' + itemHash['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash['location']['code'] + ' ' + itemHash['location']['library'] + '",code:"rmc' + '",callnumber:"' + itemHash['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                else
                  ret = ret + ' (Request in Advance) ' + b + c + ' ' + restrictions + '</div><script> itemdata["' + itemHash['barcode'] + '"] = { location:"' + itemHash['rmc']['Vault location'] + '",enumeration:"' + itemHash['enum'] + '",barcode:"' + itemHash['barcode'] + '",loc_code:"' + itemHash['location']['code'] + '",chron:"",copy:"' + itemHash['copy'].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + itemHash['rmc']['Vault location'] + '",code:"' + itemHash['location']['code'] + '",callnumber:"' + itemHash['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                end

              end
            else
              restrictions = ''
              if !itemHash['rmc'].nil?
                restrictions = itemHash['rmc']['Restrictions'] unless itemHash['rmc']['Restrictions'].nil?
              else
                restrictions = ''
              end
              if itemHash['rmc'].nil?
                itemHash['rmc'] = {}
                itemHash['rmc']['Vault location'] = if !itemHash['location']['library'].nil?
                                                      itemHash['location']['library']
                                                    else
                                                      'not in record'
                                                    end
              end
              itemHash['rmc']['Vault location'] = '' if itemHash['rmc']['Vault location'].nil?
              if itemHash['location']['name'].include?('Non-Circulating')
                #     	  	ret = itemHash["rmc"]["Vault location"]
                itemHash['call'] == '' if itemHash['call'].nil?
                # THIS IS WHERE THE PROBLEM IS
                ret = ret + "<div><label for='iid-" + itemHash['id'].to_s + "' class='sr-only'>iid-" + itemHash['id'].to_s + "</label><input class='ItemNo'  id='iid-" + itemHash['id'].to_s + "' name='iid-" + itemHash['id'].to_s + "' type='checkbox' VALUE='iid-" + itemHash['id'].to_s + "'>"
                ret = ret + ' (Available Immediately) ' + b + c + ' ' + restrictions + '</div><script> itemdata["iid-' + itemHash['id'].to_s + '"] = { location:"' + itemHash['rmc']['Vault location'] + '",enumeration:"' + itemHash['enum'] + '",barcode:"iid-' + itemHash['id'].to_s + '",loc_code:"' + itemHash['location']['code'] + '",chron:"",copy:"' + itemHash['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash['location']['code'] + ' ' + itemHash['rmc']['Vault location'] + '",code:"' + itemHash['location']['code'] + '",callnumber:"' + itemHash['call'] + '",Restrictions:"' + restrictions + '"};</script>'
              else

                # ret = ret + itemHash["barcode"]
                ret = ret + "<div><label for='iid-" + itemHash['id'].to_s + "' class='sr-only'>iid-" + itemHash['id'].to_s + "</label><input class='ItemNo'  id='iid-" + itemHash['id'].to_s + "' name='iid-" + itemHash['id'].to_s + "' type='checkbox' VALUE='iid-" + itemHash['id'].to_s + "'>"
                ret = ret + ' (Request in Advance) ' + b + c + ' ' + restrictions + '</div><script> itemdata["iid-' + itemHash['id'].to_s + '"] = { location:"' + itemHash['rmc']['Vault location'] + '",enumeration:"' + itemHash['enum'] + '",barcode:"iid-' + itemHash['id'].to_s + '",loc_code:"' + itemHash['location']['code'] + '",chron:"",copy:"' + itemHash['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash['rmc']['Vault location'] + '",code:"' + itemHash['location']['code'] + '",callnumber:"' + itemHash['call'] + '",Restrictions:"' + restrictions + '"};</script>'

              end
              d = ''
            end # barcode else
          end # do end
        else # nil end
          itemsHash = {}
          valArray = []
          enum = ''
          restrictions = ''
          unless @document['items_json'].nil?
            count = 0
            itemsHash = JSON.parse(@document['items_json'])
            itemsHash.each do |_key, value|
              next unless count < 1

              value.each do |val|
                val['location']['library'] = 'ANNEX' if val['location']['library'] == 'Library Annex'
                if !val['barcode'].nil?
                  restrictions = ''
                  if !val['rmc'].nil?
                    restrictions = val['rmc']['Restrictions'] unless val['rmc']['Restrictions'].nil?
                  else
                    val['rmc'] = {}
                    #  val["rmc"]["Vault location"].nil?
                    val['rmc']['Vault location'] = 'not in record'
                  end
                  enum = if val['enum'].nil?
                           ''
                         else
                           val['enum']
                         end
                  if val['location']['name'].include?('Non-Circulating') # or val["location"]["name"].include?('Olin Library')
                    #		ret = ret + val.inspect
                    ret = ret + "<div><label for='" + val['barcode'] + "' class='sr-only'>" + val['barcode'] + "</label><input class='ItemNo'  id='" + val['barcode'] + "' name='" + val['barcode'] + "' type='checkbox' VALUE='" + val['barcode'] + "'>"
                    if val['rmc'].nil?
                      ret = ret + ' (Available Immediately) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["' + val['barcode'] + '"] = { location:"' + val['location']['code'] + '",enumeration:"' + enum + '",barcode:"' + val['barcode'] + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['location']['library'] + '",code:"rmc' + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                    elsif val['rmc']['Vault location'].nil?
                      ret = ret + ' (Available Immediately) ' + val['call'] + ' c' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["' + val['barcode'] + '"] = { location:"' + val['location']['code'] + '",enumeration:"' + enum + '",barcode:"' + val['barcode'] + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['location']['library'] + '",code:"rmc' + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                    else
                      ret = ret + ' (Available Immediately) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["' + val['barcode'] + '"] = { location:"' + val['rmc']['Vault location'] + '",enumeration:"' + enum + '",barcode:"' + val['barcode'] + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['location']['library'] + '",code:"rmc' + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                    end
                  else
                    ret = ret + "<div><label for='" + val['barcode'] + "' class='sr-only'>" + val['barcode'] + "</label><input class='ItemNo'  id='" + val['barcode'] + "' name='" + val['barcode'] + "' type='checkbox' VALUE='" + val['barcode'] + "'>"
                    if val['rmc']['Vault location'].nil?
                      ret = ret + ' (Request in Advance) ' + val['call'] + ' c' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["' + val['barcode'] + '"] = { location:"' + val['location']['code'] + '",enumeration:"' + enum + '",barcode:"' + val['barcode'] + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['location']['library'] + '",code:"rmc' + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                    else
                      ret = ret + ' (Request in Advance) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["' + val['barcode'] + '"] = { location:"' + val['rmc']['Vault location'] + '",enumeration:"' + enum + '",barcode:"' + val['barcode'] + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['location']['library'] + '",code:"' + val['location']['code'] + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                    end
                  end

                else
                  restrictions = ''
                  restrictions = val['rmc']['Restrictions'] if !val['rmc'].nil? && !val['rmc']['Restrictions'].nil?
                  if val['location']['name'].include?('Non-Circulating')
                    ret = ret + "<div><label for='iid-" + val['id'].to_s + "' class='sr-only'>iid-" + val['id'].to_s + "</label><input class='ItemNo'  id='iid-" + val['id'].to_s + "' name='iid-" + val['id'].to_s + "' type='checkbox' VALUE='iid-" + val['id'].to_s + "'>"
                    ret = ret + ' (Available Immediately) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["iid-' + val['id'].to_s + '"] = { location:"' + val['rmc']['Vault location'] + '",enumeration:"' + enum + '",barcode:"iid-' + val['id'].to_s + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['location']['library'] + '",code:"' + val['location']['code'] + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                  else
                    # ret = ret + itemHash["barcode"]
                    ret = ret + "<div><label for='iid-" + val['id'].to_s + "' class='sr-only'>iid-" + val['id'].to_s + "</label><input class='ItemNo'  id='iid-" + val['id'].to_s + "' name='iid-" + val['id'].to_s + "' type='checkbox' VALUE='iid-" + val['id'].to_s + "'>"
                    ret = ret + ' (Requests in Advance) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["iid-' + val['id'].to_s + '"] = { location:"' + val['rmc']['Vault location'] + '",enumeration:"' + enum + '",barcode:"iid-' + val['id'].to_s + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['location']['library'] + '",code:"' + val['location']['code'] + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
                  end
                end # barcode else
              end
              count += 1
            end
          end

        end
        # end
        count += 1
      end # end of  itemsHash.each do |key, value|
    else # if itemsHash.empty
      itemsHash = {}
      valArray = []
      enum = ''
      restrictions = ''
      unless holdingsHash.nil?
        count = 0
        itemsHash = JSON.parse(@document['holdings_json'])
        #	ret = itemsHash.inspect
        itemsHash.each do |_key, val|
          next unless count < 1

          #		value.each do |key, val|
          #		  ret = ret + val.inspect
          if !val['barcode'].nil?
            restrictions = ''
            if !val['rmc'].nil?
              restrictions = val['rmc']['Restrictions'] unless val['rmc']['Restrictions'].nil?
            else
              val['rmc'] = {}
              #  val["rmc"]["Vault location"].nil?
              val['rmc']['Vault location'] = 'not in record'
            end
            enum = '' if val['enum'].nil?
            if val['location']['name'].include?('Non-Circulating')
              ret = ret + "<div><label for='" + val['barcode'] + "' class='sr-only'>" + val['barcode'] + "</label><input class='ItemNo'  id='" + val['barcode'] + "' name='" + val['barcode'] + "' type='checkbox' VALUE='" + val['barcode'] + "'>"
              if val['rmc'].nil?
                #		ret = ret + val["location"]["name"] + " (Available Immediately) " + val["call"] + " c " +  val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                ret = ret + val['location']['name'] + ' (Available Immediately) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["' + val['barcode'] + '"] = { location:"' + val['location']['code'] + '",enumeration:"' + enum + '",barcode:"' + val['barcode'] + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['rmc']['Vault location'] + '",code:"rmc' + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
              elsif val['rmc']['Vault location'].nil?
                ret = ret + ' (Available Immediately) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["' + val['barcode'] + '"] = { location:"' + val['location']['code'] + '",enumeration:"' + val['enum'] + '",barcode:"' + val['barcode'] + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['location']['library'] + '",code:"rmc' + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
              else
                #  	        	    					ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                ret = ret + ' (Available Immediately) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["' + val['barcode'] + '"] = { location:"' + val['rmc']['Vault location'] + '",enumeration:"' + val['enum'] + '",barcode:"' + val['barcode'] + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['rmc']['Vault loation'] + '",code:"rmc' + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
              end
            else
              # ret = ret + itemHash["barcode"]
              ret = ret + "<div><label for='" + val['barcode'] + "' class='sr-only'>" + val['barcode'] + "</label><input class='ItemNo'  id='" + val['barcode'] + "' name='" + val['barcode'] + "' type='checkbox' VALUE='" + val['barcode'] + "'>"
              ret = ret + ' (Request in Advance) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["' + val['barcode'] + '"] = { location:"' + val['rmc']['Vault location'] + '",enumeration:"' + val['enum'] + '",barcode:"' + val['barcode'] + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['location']['library'] + '",code:"' + val['location']['code'] + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
            end
          # ret = "baby"
          else
            restrictions = ''
            if !val['rmc'].nil?
              restrictions = val['rmc']['Restrictions'] unless val['rmc']['Restrictions'].nil?
            else
              val['rmc'] = {}
              #  val["rmc"]["Vault location"].nil?
              val['rmc']['Vault location'] = 'not in record'
            end
            #        ret = ret + val.inspect
            if val['location']['name'].include?('Non-Circulating')
              ret = ret + "<div><label for='iid-" + val['hrid'].to_s + "' class='sr-only'>iid-" + val['hrid'].to_s + "</label><input class='ItemNo'  id='iid-" + val['hrid'].to_s + "' name='iid-" + val['hrid'].to_s + "' type='checkbox' VALUE='iid-" + val['hrid'].to_s + "'>"
              #  	        					ret = ret + val["location"]["library"] + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["hrid"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["hrid"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
              ret = ret + val['location']['library'] + ' (Available Immediately) ' + val['call'] + ' c ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["iid-' + val['hrid'].to_s + '"] = { location:"' + val['rmc']['Vault location'] + '",enumeration:"' + enum + '",barcode:"iid-' + val['hrid'].to_s + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['rmc']['Vault location'] + '",code:"' + val['location']['code'] + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
            else
              # ret = ret + itemHash["barcode"]
              ret = ret + "<div><label for='iid-" + val['id'].to_s + "' class='sr-only'>iid-" + val['id'].to_s + "</label><input class='ItemNo'  id='iid-" + val['id'].to_s + "' name='iid-" + val['id'].to_s + "' type='checkbox' VALUE='iid-" + val['id'].to_s + "'>"
              #    					ret = ret + " (Requests in Advance) " + val["call"] + " " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
              ret = ret + ' (Requests in Advance) ' + val['call'] + ' ' + val['copy'].to_s + ' ' + restrictions + '</div><script> itemdata["iid-' + val['id'].to_s + '"] = { location:"' + val['rmc']['Vault location'] + '",enumeration:"' + enum + '",barcode:"iid-' + val['id'].to_s + '",loc_code:"' + val['location']['code'] + '",chron:"",copy:"' + val['copy'].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val['location']['code'] + ' ' + val['rmc']['Vault location'] + '",code:"' + val['location']['code'] + '",callnumber:"' + val['call'] + '",Restrictions:"' + restrictions + '"};</script>'
            end
          end # barcode else

          #		end
          count += 1
        end
      end
    end # end of if itemsHash.empty
    ret + "<!--Producing menu with items no need to refetch data. ic=**$ic**\n -->"
    #   ret = @document["items_json"]
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
