# frozen_string_literal: true

# This file contains helper methods for the Aeon request forms
module AeonHelper
  def holdings(holdings_json_hash, items_json_hash)
    # valholding = []
    # TODO: This code doesn't make sense to me. Given a hash of the form
    # { holdings_id1 => [ {item1} ], holdings_id2 => [ {item2} ] },
    # this produces { holdings_id1 => [ {item1, item2} ], holdings_id2 => [ {item1, item2} ] }.
    # I see no good reason to combine all the items from all the holdings into a single array for
    # each holding, and then duplicate that array for each holding. But without doing that, the items are not displayed
    # correctly in the view. This should be revisited once I understand that cause and effect better.

    # items_json_hash.each do |holding_id, items|
    #   items.each do |item|
    #     valholding << item
    #   end
    #   items = valholding
    #   begin
    #     items.sort_by! { |e| e['enum'].scan(/\D+|\d+/).map { |x| x =~ /\d/ ? x.to_i : x } }
    #   rescue StandardError
    #     items.sort_by! { |k| k['enum'] }
    #   end
    #   items_json_hash[holding_id] = items
    # end

    
    valholding = items_json_hash.values.flatten
    items_json_hash.transform_values! { |items| sort_items(valholding.dup) }
    
    res  = xholdings(holdings_json_hash, items_json_hash)
    Rails.logger.debug res
    res
  end

  # TODO: This method is a monster. It definitely needs refactoring and cleanup, but that's a project in itself.
  def xholdings(holdings_hash, items_hash)
    ret = ''
    holding_id = ''
    count = 0
    if items_hash.present?
      items_hash.each_key do |key|
        if count < 1
          holding_id = key
          items = items_hash[holding_id]

          c = ''
          b = ''
          d = ''
          if items.present?
            items.each do |item|
              loc_code = item['location']['code']
              next unless loc_code.include?('rmc') || loc_code.include?('rare')

              b = item['call'].to_s
              b = b.sub('Archives ', '')

              item['location']['library'] = 'ANNEX' if item['location']['library'] == 'Library Annex'

              if item['copy']
                c =  " c. #{item['copy']}"
                if item['enum'].present?
                  c += " #{item['enum']}"
                elsif item['chron'].present?
                  c += " #{item['chron']}"
                end
                if item['caption']
                  c += " #{item["caption"]}"
                end
              end

              d = item['caption'].nil? ? '' : " #{item['caption']}"

              item['enum'] ||= ''
              holdings_hash[holding_id]['call'] ||= ''

              restrictions = ''
              if item['barcode']
                if item['rmc']
                  restrictions = item['rmc']['Restrictions'] || ''
                else
                  item['rmc'] = {}
                  item['rmc']['Vault location'] = item['location'] ? "#{item['location']['code']} #{item['location']['library']}" : 'Not in record'
                end
                if item['location']['name'].include?('Non-Circulating')
                  ret += labeled_checkbox(item['barcode'])
                    if item['rmc'].nil?
                      ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div><script> itemdata["' + item["barcode"] + '"] = { location:"' + item['location']["code"] + '",enumeration:"' + item["enum"] + '",barcode:"' + item["barcode"] + '",loc_code:"' + item['location']["code"] +'",chron:"",copy:"' + item["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item['location']["code"] + ' ' + item['location']["library"] + '",code:"rmc' +  '",callnumber:"' + item["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                    else
                      if item['rmc']['Vault location'].nil?
                        ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div><script> itemdata["' + item["barcode"] + '"] = { location:"' + item['location']["code"] + '",enumeration:"' + item["enum"] + '",barcode:"' + item["barcode"] + '",loc_code:"' + item['location']["code"] +'",chron:"",copy:"' + item["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item['location']["code"] + ' ' + item['location']["library"] + '",code:"rmc' +  '",callnumber:"' + item["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                      else
                        # for requests to route into Awaiting Restriction Review, the cslocation needs both the vault and the building 
                        vault_location = item['rmc']['Vault location']
                        location_code = item['location']["code"]
                        cslocation = vault_location.include?(location_code) ? vault_location : vault_location + ' ' + location_code
                        ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div><script> itemdata["' + item["barcode"] + '"] = { location:"' + vault_location + '",enumeration:"' + item["enum"] + '",barcode:"' + item["barcode"] + '",loc_code:"' + vault_location +'",chron:"",copy:"' + item["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + cslocation + '",code:"rmc' +  '",callnumber:"' + item["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                      end
                    end
                  else
                    ret += labeled_checkbox(item['barcode'])
                    if item['rmc']['Vault location'].nil?
                      ret = ret + " (Request in Advance) " + b + c + "  " + restrictions + '</div><script> itemdata["' + item["barcode"] + '"] = { location:"' + item['location']["code"] + '",enumeration:"' + item["enum"] + '",barcode:"' + item["barcode"] + '",loc_code:"' + item['location']["code"] +'",chron:"",copy:"' + item["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item['location']["code"] + ' ' + item['location']["library"] + '",code:"rmc' +  '",callnumber:"' + item["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                    else
                      ret = ret + " (Request in Advance) " + b + c  + " " + restrictions  +  '</div><script> itemdata["' + item["barcode"] + '"] = { location:"' + item['rmc']['Vault location'] + '",enumeration:"' + item["enum"] + '",barcode:"' + item["barcode"] + '",loc_code:"' + item['location']["code"] +'",chron:"",copy:"' + item["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + item['rmc']['Vault location'] + '",code:"' + item['location']["code"] + '",callnumber:"' + item["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                    end
                  end
                else
                  if !item['rmc'].nil?
                    if !item['rmc']["Restrictions"].nil?
                      restrictions = item['rmc']["Restrictions"]
                    end
                  else
                    restrictions = ""
                  end
                  if item['rmc'].nil?
                    item['rmc'] = {}
                    if !item['location']['library'].nil?
                      item['rmc']['Vault location'] = item['location']['library']
                    else
                      item['rmc']['Vault location'] = "not in record"
                    end
                  end
                  if item['rmc']['Vault location'].nil?
                    item['rmc']['Vault location'] = ""
                  end
                  if item['location']['name'].include?('Non-Circulating')
                    # ret = item['rmc']['Vault location']
                    if item["call"].nil?
                      item["call"] == ""
                    end
                    # THIS IS WHERE THE PROBLEM IS
                    ret += labeled_checkbox("iid-#{val['id']}")
                    ret = ret + " (Available Immediately) " + b + c + " " + restrictions + '</div><script> itemdata["iid-' + item["id"].to_s + '"] = { location:"' + item['rmc']['Vault location'] + '",enumeration:"' + item["enum"] + '",barcode:"iid-' + item["id"].to_s + '",loc_code:"' + item['location']["code"] +'",chron:"",copy:"' + item["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item['location']["code"] + ' ' + item['rmc']['Vault location'] + '",code:"' + item['location']["code"] + '",callnumber:"' + item["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                  else
                    # ret = ret + item["barcode"]
                    ret += labeled_checkbox("iid-#{val['id']}")
                    ret = ret + " (Request in Advance) " + b + c + " " + restrictions + '</div><script> itemdata["iid-' + item["id"].to_s + '"] = { location:"' + item['rmc']['Vault location'] + '",enumeration:"' + item["enum"] + '",barcode:"iid-' + item["id"].to_s + '",loc_code:"' + item['location']["code"] +'",chron:"",copy:"' + item["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + item['rmc']['Vault location'] + '",code:"' + item['location']["code"] + '",callnumber:"' + item["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                  end
                  d = ''
                end #barcode else
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
                      restrictions = ''
                      if !val["rmc"].nil?
                        if !val["rmc"]["Restrictions"].nil?
                          restrictions = val["rmc"]["Restrictions"]
                        end
                      else
                        val["rmc"] = {}
                        #  val["rmc"]['Vault location'].nil?
                        val["rmc"]['Vault location'] = "not in record"
                      end
                      if val["enum"].nil?
                        enum = ''
                      else
                        enum = val["enum"]
                      end
                      if val["location"]['name'].include?('Non-Circulating') #or val["location"]['name'].include?('Olin Library')
                        #		ret = ret + val.inspect
                        ret += labeled_checkbox(val['barcode'])
                        if val["rmc"].nil?
                          ret = ret + " (Available Immediately) " + val["call"] + " c " +  val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                        else
                          if val["rmc"]['Vault location'].nil?
                            ret = ret + " (Available Immediately) " + val["call"] + " c" + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                          else
                            ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]['Vault location'] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                          end
                        end
                      else
                        ret += labeled_checkbox(val['barcode'])
                        if val["rmc"]['Vault location'].nil?
                          ret = ret + " (Request in Advance) " + val["call"] + " c" + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                        else
                          ret = ret + " (Request in Advance) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions  +  '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]['Vault location'] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                        end
                      end
                    else
                      restrictions = ''
                      if !val["rmc"].nil?
                        if !val["rmc"]["Restrictions"].nil?
                          restrictions = val["rmc"]["Restrictions"]
                        end
                      end
                      if val["location"]['name'].include?('Non-Circulating')
                        ret += labeled_checkbox("iid-#{val['id']}")
                        ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]['Vault location'] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                      else
                        ret += labeled_checkbox("iid-#{val['id']}")
                        ret = ret + " (Requests in Advance) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]['Vault location'] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
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
                #  val["rmc"]['Vault location'].nil?
                val["rmc"]['Vault location'] = "not in record"
              end
              if val["enum"].nil?
                enum = ""
              end
              if val["location"]['name'].include?('Non-Circulating')
                ret += labeled_checkbox(val['barcode'])
                if val["rmc"].nil?
                  ret = ret + val["location"]['name'] + " (Available Immediately) " + val["call"] + " c " +  val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]['Vault location'] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                else
                  if val["rmc"]['Vault location'].nil?
                    ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                  else
                    ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]['Vault location'] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]["Vault loation"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                  end
                end
              else
                ret += labeled_checkbox(val['barcode'])
                ret = ret + " (Request in Advance) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions  +  '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]['Vault location'] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
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
                #  val["rmc"]['Vault location'].nil?
                val["rmc"]['Vault location'] = "not in record"
              end
              #        ret = ret + val.inspect
              if val["location"]['name'].include?('Non-Circulating')
                ret += labeled_checkbox("iid-#{val['hrid']}")
                ret = ret + val["location"]["library"] + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["hrid"].to_s + '"] = { location:"' + val["rmc"]['Vault location'] + '",enumeration:"' + enum + '",barcode:"iid-' + val["hrid"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]['Vault location'] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
              else
                # ret = ret + item["barcode"]
                ret += labeled_checkbox("iid-#{val['id']}")
                ret += <<~HTML
                  (Requests in Advance) #{val["call"]} #{val["copy"].to_s} #{restrictions}</div>
                  <script>
                    itemdata["iid-#{val["id"].to_s}"] = {
                      location: "#{val["rmc"]['Vault location']}",
                      enumeration: "#{enum}",
                      barcode: "iid-#{val["id"].to_s}",
                      loc_code: "#{val["location"]["code"]}",
                      chron: "",
                      copy: "#{val["copy"].to_s}",
                      free: "",
                      caption: "",
                      spine: "",
                      cslocation: "#{val["location"]["code"]} #{val["rmc"]['Vault location']}",
                      code: "#{val['location']["code"]}",
                      callnumber: "#{val["call"]}",
                      Restrictions: "#{restrictions}"
                    };
                  </script>
                HTML
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

  def sort_items(items)
    items.sort_by do |item|
      enum = item['enum']
      enum.scan(/\D+|\d+/).map { |x| x =~ /\d/ ? x.to_i : x }
    rescue StandardError
      enum
    end
  end

  
  # Generates an HTML snippet for a labeled checkbox. (Note that the div is not closed in this method.)
  #
  # @param id [String] The ID of the checkbox.
  # @return [String] The HTML snippet for the labeled checkbox.
  def labeled_checkbox(id)
    <<~HTML
      <div>
        <label for='#{id}' class='sr-only'>#{id}</label>
        <input class='ItemNo' id='#{id}' name='#{id}' type='checkbox' VALUE='#{id}'>
    HTML
  end
end
