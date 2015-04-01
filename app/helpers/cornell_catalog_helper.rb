module CornellCatalogHelper
 require "pp"
 require "maybe"

  # Determine if user query can be expanded to WCL & Summon
  def expandable_search?
    params[:q].present? and !params[:advanced_search] and !params[:click_to_search]
  end

  def process_online_title(title)
    # Trim leading and trailing text
    # Reformat coverage dates to simply mm/yy (drop day) and wrap in span for display
    title_dirty = ERB::Util.html_escape(title)
    title_clean = title_dirty.to_s.gsub(/^Full text available from /, '').gsub(/(\d{1,2})\/\d{1,2}(\/\d{4})/, '\1\2').gsub(/\sConnect to full text\.$/, '').gsub(/(:\s)(\d{1,2}\/\d{4}\sto\s.{0,})/, ' <span class="online-coverage">(\2)</span>')
    # Address the Factiva links that come with a lengthy note
    title_clean.to_s.gsub(/(Please check resource for coverage or contact a librarian for assistance.)$/, '<span class="online-note">\1</span>').html_safe
  end

  # Group holding items into circulating, interwebs and rare (sort rare last)
  def group_holdings holdings
    holdings.inject({}) do |grouped, holding|
      grouped['Circulating'] = [] if grouped['Circulating'].nil?
      grouped['*Online'] = [] if grouped ['*Online'].nil?
      grouped['Rare'] = [] if grouped['Rare'].nil?
      #if holding['location_code'].include?('rmc')
      if aeon_eligible? holding['location_code']
        grouped['Rare'] << holding
      elsif holding['location_name'].include?('*Networked Resource')
        grouped['*Online'] << holding
      else
        grouped['Circulating'] << holding
      end
      # Remove empty groups (no holdings)
      grouped.select! { |group, items| items.present? }
      # Sort groups by key so rare is last & *online is first
      Hash[grouped.sort]
    end
  end

  ITEM_STATUS_RANKING = ['available', 'some_available', 'not_available', 'none', 'online']

  def sort_item_statuses(entries)

    entries.each do |entry|
      entry['copies'].each do |copy|
        items = copy['items']
        copy['items'] = items.sort_by { |k,v| ITEM_STATUS_RANKING.index(v['status']) }
      end
    end

    # NOTE: This sort_by step changes the copy[:items] structure from:
    #       {message => {:status => , :count => , etc.}, ...}
    #     to:
    #       [[message, {:status => , :count => , etc.}], ...]
    # in order to preserve the sort order.

  end

  def extract_google_bibkeys(document)

    bibkeys = []

    unless document["isbn_t"].nil?
      bibkeys << document["isbn_t"]
    end

    unless document["oclc_display"].nil?
      bibkeys << document["oclc_display"].collect { |oclc| "OCLC:" + oclc.gsub(/^oc[mn]/,"") }.uniq
    end

    unless document["lccn_display"].nil?
      bibkeys << document["lccn_display"].collect { |lccn| "LCCN:" + lccn.gsub(/\s/,"").gsub(/\/.+$/,"") }
    end

    bibkeys.flatten

  end

  AEON_SITES  = [
    'lawr' ,
    'rmc' ,
    'rmc,anx',
    'rmc,icer',
    'rmc,hsci',
    'was,rare',
    'was,ranx',
    'ech,rare',
    'ech,ranx',
    'sasa,rare',
    'sasa,ranx',
    'hote,rare'
  ]

  def aeon_eligible?(lib)
    return AEON_SITES.include?(lib)
  end

  # Using data from solr, and from oracle -- create the condensed_full structure
  # needed by the display logic.
  def create_condensed_full(document)
    # the beginnings of this code due to sk274, then mangled to try to
    # simulate the behavior of the holding server
    # when called with .../retrieve/bibid to produce a condensed_holdings_full structure.
    Rails.logger.debug "\nSTART of create_condensed #{__LINE__} #{__FILE__} \n -----es287_debug: document =  #{document.inspect}"
    Rails.logger.debug "\n-----es287_debug: end of document"
    items2 = document[:item_record_display].present? ? document[:item_record_display].map { |item| JSON.parse(item).with_indifferent_access } : Array.new
    bibid = document[:id]
    response = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/status_short/#{bibid}")).with_indifferent_access
    @response = response
    # items might differ slightly from direct db response.
    # reconcile the two into a grand synthesis of merged info 
    #items  = items2
    items,items_solr  = fix_items(items2,bibid, response) 
    Rails.logger.debug "\nes287_debug file:#{__FILE__} line:#{__LINE__}  merged items = " + items.inspect 
    Rails.logger.debug "\nes287_debug file:#{__FILE__} line:#{__LINE__}  merged items solr = " + items_solr.inspect 
    Rails.logger.debug "\nes287_debug file:#{__FILE__} line:#{__LINE__}  response status/short/#{bibid}= " + response.inspect 
    @current_hldgs = response["#{bibid}"]["#{bibid}"]["records"][0]
    Rails.logger.debug "\nes287_debug file:#{__FILE__} line:#{__LINE__} holdings/#{bibid}= " + @current_hldgs.inspect 
    if (!response["#{bibid}"]["#{bibid}"]["records"].nil? && !response["#{bibid}"]["#{bibid}"]["records"][0].nil? &&  !response["#{bibid}"]["#{bibid}"]["records"][0]["current_suppl"].nil?) 
      Rails.logger.debug "\nes287_debug file:#{__FILE__} line:#{__LINE__}  status_short current_suppl in response = " + response["#{bibid}"]["#{bibid}"]["records"][0]["current_suppl"].inspect 
      @current_suppl = response["#{bibid}"]["#{bibid}"]["records"][0]["current_suppl"] 
    end
    locations_by_iid,statuses,items_by_lid,items_by_hid,statuses_as_text,orders_by_mid = parse_item_status(bibid,response,items_solr)
    locnames_by_lid = parse_item_locs(bibid,response)
    Rails.logger.debug "\nes287_debug file:#{__FILE__} #{__LINE__} statuses = " + statuses.inspect 
    Rails.logger.debug "\nes287_debug statuses as text file:#{__FILE__} #{__LINE__} = " + statuses_as_text.inspect 
    Rails.logger.debug "\nes287_debug dispname by iid line file:#{__FILE__} #{__LINE__} = " + locations_by_iid.inspect 
    Rails.logger.debug "\nes287_debug items by lid line #{__LINE__} = " + items_by_lid.inspect 
    Rails.logger.debug "\nes287_debug orders by hid line #{__LINE__} = " + orders_by_mid.inspect 
    #grouped = group_item_statuses(bibid,statuses,items_by_hid,locations_by_iid)
    grouped = group_item_statuses(bibid,statuses_as_text,items_by_hid,locations_by_iid)
    Rails.logger.debug "\nes287_debug grouped line #{__LINE__}  = " + grouped.inspect 
    # holdings notes created by either temp or perm location overrides in item record. 
    over_locs = {} 
    # all over riding location info
    over_info = {} 
    # condensed holdings indexed by display name and holding id.
    condensed = {} 
    # notes by holding id 
    notes_by_mid = {} 
    # summary holdings by holding id. 
    sumh_by_mid = {} 
    hrds = {}
    Rails.logger.debug "\nes287_debug raw holding data #{__LINE__}   = " 
    document[:holdings_record_display].each do |hrd|
        Rails.logger.debug "\nes287_debug one holding #{__LINE__}  = " + hrd.inspect 
    end  if document[:holdings_record_display]
    document[:holdings_record_display].each do |hrd|
          hrdJSON = JSON.parse(hrd).with_indifferent_access
          Rails.logger.debug "\nes287_debug file:#{__FILE__} line:#{__LINE__} hrdJSON  = " + hrdJSON.inspect 
          callnumber = "" 
          callnumber = hrdJSON["callnos"][0] unless  hrdJSON["callnos"].blank?		
          id = hrdJSON[:id]
          hrds[id]  =  hrdJSON
          notes = hrdJSON[:notes]
          #summary_holdings = recent_holdings = suppl_holdings = index_holdings = [] 
          summary_holdings = hrdJSON[:holdings_desc]
          recent_holdings = hrdJSON[:recent_holdings_desc]
          suppl_holdings = hrdJSON[:supplemental_holdings_desc]
          index_holdings = hrdJSON[:index_holdings_desc]
          #Rails.logger.debug "\nes287_debug notes  = " + notes.inspect 
          Rails.logger.debug "\nes287_debug **** #{__FILE__}:#{__LINE__} summary holdings  = " + summary_holdings.inspect 
          hrdJSON[:locations].each do |loc|
            oneloc = {} 
            dispname = loc[:name] 
            oneloc["location_name"] = dispname 
            oneloc["location_code"] = loc[:code]
            Rails.logger.debug "\nes287_debug **** #{__FILE__}:#{__LINE__} location code  = " + loc[:code] 
            oneloc["holding_id"] = [id] 
            mfhd_id = id.to_i 
            oneloc["call_number"] = callnumber
            if callnumber.blank?  && !@current_hldgs.nil? && !@current_hldgs['call_number'].blank?
              oneloc["call_number"] = @current_hldgs['call_number']
            end
            oneloc["copies"] = []
            oneloc["notes"] = "Notes: " + notes.join(' ') unless notes.blank? 
            notes_by_mid[id.to_s] = oneloc["notes"]
            oneloc["summary_holdings"]="Library has: " + summary_holdings.join(' ') unless summary_holdings.blank? 
            oneloc["supplements"]=suppl_holdings.join(';') unless suppl_holdings.blank? 
            if (!@current_suppl.nil?) 
              if !(@current_suppl.select{|x| x["MFHD_ID"] ==  mfhd_id  && x["PREDICT"] == 'Y'}).blank?
                Rails.logger.debug "\nes287_debug **** #{__FILE__}:#{__LINE__} selected current  = " +  (@current_suppl.select{|x| x["MFHD_ID"] ==  mfhd_id }).inspect
                cur =  (@current_suppl.select{|x| x["MFHD_ID"] ==  mfhd_id  && x["PREDICT"] == 'Y'}).sort_by{|x| x["ISSUE_ID"]}
                Rails.logger.debug "\nes287_debug **** #{__FILE__}:#{__LINE__} sorted current  = " +  cur.inspect
                currev = cur.reverse.map{|x| x["ENUMCHRON"]}.join(";") 
                Rails.logger.debug "\nes287_debug **** #{__FILE__}:#{__LINE__} sorted and reversed  = " +  currev.inspect
                oneloc["current_issues"] = "Current Issues: " + currev
                #oneloc["current_issues"]="Current Issues: " + ((@current_suppl.select{|x| x["MFHD_ID"] ==  mfhd_id  && x["PREDICT"] == 'Y'}).map{|x| x["ENUMCHRON"]}).sort_by{|x| x["ISSUE_ID"]}.reverse.join(";") 
              end
              if !(@current_suppl.select{|x| x["MFHD_ID"] ==  mfhd_id && x["PREDICT"] == 'N'}).blank?
                suppl =  (@current_suppl.select{|x| x["MFHD_ID"] ==  mfhd_id  && x["PREDICT"] == 'N'}).sort_by{|x| x["ISSUE_ID"]}
                Rails.logger.debug "\nes287_debug **** #{__FILE__}:#{__LINE__} sorted suppl  = " +  suppl.inspect
                supplrev = suppl.reverse.map{|x| x["ENUMCHRON"]}.join(";") 
                Rails.logger.debug "\nes287_debug **** #{__FILE__}:#{__LINE__} sorted and reversed  = " +  supplrev.inspect
                oneloc["supplements"]=supplrev 
              end
            end
            oneloc["indexes"]="Indexes: " + index_holdings.join(' ') unless index_holdings.blank? 
            sumh_by_mid[id.to_s] = oneloc["summary_holdings"] 
            Rails.logger.debug "\nes287_debug oneloc = " + oneloc.inspect 
            Rails.logger.debug "\nes287_debug dispname = " + dispname 
            if condensed[id.to_s].blank?    
              condensed[id.to_s]  =  oneloc
            else
              condensed[id.to_s]["holding_id"] << id 
            end
          end
    end if document[:holdings_record_display]
    # condensed has holding info, keyed by location name, as string, like "Library Annex" 
    Rails.logger.debug "\nes287_debug #{__FILE__} #{__LINE__} condensed (by holding id as string) = " + condensed.inspect 
    Rails.logger.debug "\nes287_debug #{__FILE__} #{__LINE__} notes_by_mid = " + notes_by_mid.inspect 
    Rails.logger.debug "\nes287_debug #{__FILE__} #{__LINE__} sumh_by_mid = " + sumh_by_mid.inspect 
    over_locs,over_info = parse_over_info(hrds,condensed,items,locnames_by_lid)
    Rails.logger.debug "\nes287_debug over_locs #{__FILE__} line:(#{__LINE__})   = " + over_locs.inspect 
    Rails.logger.debug "\nes287_debug over_info #{__FILE__} line:(#{__LINE__})   = " + over_info.inspect 
    #condensed = condensed.merge(over_condensed)
    Rails.logger.debug "\nes287_debug orders by hid line #{__FILE__} #{__LINE__} = " + orders_by_mid.inspect 
    parse_item_info(condensed,items,notes_by_mid,sumh_by_mid,grouped,bibid,response,over_locs,orders_by_mid)
    condensed_full =  [] 
    condensed.each_key  do |k| 
      condensed_full << condensed[k]
    end
    Rails.logger.debug "\nes287_debug #{__FILE__} #{__LINE__} condensed  = " + condensed.inspect 
    Rails.logger.debug "\nes287_debug #{__FILE__} #{__LINE__} condensed full (before sort)  = " + condensed_full.inspect 
    condensed_full.sort_by! { | h | h["location_name"] } 

    condensed_full.each  do |h| 
      if h['copies'].size < 1 
       #h['copies'][0]  =  {"items" => {"Status unknown" => {"status"=> "none","count" =>1}}}
       h['copies'][0]  =  {"items" => {"Status unknown" => {"status"=> "none","count" =>0}}}
       Rails.logger.debug "\nes287_debug (copying data to copies array)file #{__FILE__} line:#{__LINE__} h  = " + h['copies'][0].inspect 
       ['notes','summary_holdings','indexes','current_issues','supplements'].each do |k|
        if h[k] 
          Rails.logger.debug "\nes287_debug file  summary etc.  #{__FILE__} line:#{__LINE__} h,#{k} =" + h[k].inspect 
          h['copies'][0][k]  =  h[k]
        end
       end
      end
    end
    Rails.logger.debug "\nes287_debug #{__LINE__} condensed full (after sort) = " + condensed_full.inspect 
    condensed_full = trim_avail(condensed_full)
    Rails.logger.debug "\nes287_debug #{__LINE__} condensed full (after trim avail) = " + condensed_full.inspect 
    condensed_full = fix_notes(condensed_full)
    Rails.logger.debug "\nes287_debug #{__LINE__} condensed full (after fix notes) = " + condensed_full.inspect 
    zcondensed_full = fix_permtemps(bibid,condensed_full,response)
    Rails.logger.debug "\nes287_debug #### #{__FILE__} #{__LINE__} condensed full (after fix perm temps) = " + zcondensed_full.inspect 
    ycondensed_full = collapse_locs(zcondensed_full)
    Rails.logger.debug "\nes287_debug #{__LINE__} condensed full (after collapse locs) = " + condensed_full.inspect 
    ycondensed_full
  end

  def parse_item_locs(bibid,response)
    locnames_by_lid = {}
    if response[bibid] and response[bibid][bibid] and response[bibid][bibid][:records]
      response[bibid][bibid][:records].each do |record|
        if record[:bibid].to_s == bibid
          record[:holdings].each do |holding|
              locnames_by_lid[holding[:LOCATION_ID].to_s] = {:display_name=>holding[:LOCATION_DISPLAY_NAME],
                :location_code =>holding[:LOCATION_CODE]} unless holding[:LOCATION_ID].to_s.blank?
              locnames_by_lid[holding[:TEMP_LOCATION_ID].to_s]= {:display_name=>holding[:TEMP_LOCATION_DISPLAY_NAME],
                :location_code =>holding[:TEMP_LOCATION_CODE]}unless holding[:TEMP_LOCATION_ID].to_s.blank?
              locnames_by_lid[holding[:PERM_LOCATION].to_s]= {:display_name=>holding[:PERM_LOCATION_DISPLAY_NAME], 
                :location_code =>holding[:PERM_LOCATION_CODE]}unless holding[:PERM_LOCATION].to_s.blank?
            #end
          end
        end
      end
    end
  return locnames_by_lid 
  end

  # given hlding records, and condensed info
  #  and items, create a list of temp_locations that shows the (possibly temporary) 
  #  library location that is to displayed as part of the holding display
  def parse_over_info(hrds,condensed,items,locnames_by_lid)
    over = {} 
    overinfo = {} 
    ocnt = {} # how many items have an over ridden location, either temp OR perm, indexed by  number
    total = {} # how many items are in a location 
    Rails.logger.debug "\nes287_debug saved response  file:#{__FILE__} line:(#{__LINE__}) @response= " + @response.inspect 
    Rails.logger.debug "\nes287_debug all holdings records from document  file:#{__FILE__} line:(#{__LINE__}) hrds= " + hrds.inspect 
    Rails.logger.debug "\nes287_debug locnames by lid document  file:#{__FILE__} line:(#{__LINE__}) locnames by lid= " + locnames_by_lid.inspect 
    Rails.logger.debug "\nes287_debug number of items  file:#{__FILE__} line:(#{__LINE__})= " + items.size.to_s 
    items.each do |iinfo|
      tmploc = {}
      mid = iinfo['mfhd_id']
      Rails.logger.debug "\nes287_debug item  file:#{__FILE__} line:(#{__LINE__}) iinfo= " + iinfo.inspect 
      Rails.logger.debug "\nes287_debug item  file:#{__FILE__} line:(#{__LINE__}) hrds[mid]= " + hrds[mid].inspect 
      #
      next if hrds[mid].nil? 
      Rails.logger.debug "\nes287_debug hrds  file:#{__FILE__} line:(#{__LINE__}) location id = " + hrds[mid]["locations"][0]["number"].to_s 
      lid   =  hrds[mid]["locations"][0]["number"].to_s 
      Rails.logger.debug "\nes287_debug item file:#{__FILE__} line:(#{__LINE__}) mid = " + mid.inspect 
      Rails.logger.debug "\nes287_debug class of permlocation file:#{__FILE__} line:(#{__LINE__}) class = " + iinfo[:perm_location].class.to_s 
      dispname = ""
      dcode = " "
      if iinfo[:perm_location].class == ActiveSupport::HashWithIndifferentAccess 
        dcode = iinfo[:perm_location][:number].to_s
        dispname = iinfo[:perm_location][:name] 
      else 
        if !iinfo["perm_location"].blank?
          dcode = iinfo["perm_location"]
          Rails.logger.debug "\nes287_debug class of permlocation file:#{__FILE__} line:(#{__LINE__}) dcode = " + dcode.inspect 
          dispname = locnames_by_lid[dcode][:display_name] unless dcode.blank?
        end
      end 
      Rails.logger.debug "\nes287_debug dcode file:#{__FILE__} line:(#{__LINE__}) dcode = " + dcode.inspect 
      if dcode != " " &&   dcode != hrds[mid]["locations"][0]["number"].to_s
      # if iinfo['perm_location'] != hrds[mid]["locations"][0]["number"].to_s 
        Rails.logger.debug "\nes287_debug item  file:#{__FILE__} line:(#{__LINE__}) OVERRIDDEN  by item perm location = " + iinfo['perm_location'].inspect 
        Rails.logger.debug "\nes287_debug locnames by lid file:#{__FILE__}  line:(#{__LINE__}) = " + locnames_by_lid.inspect 
        ocnt[lid]  =  ocnt[lid].blank? ?  1 : ocnt[lid]+1   
        total[lid]  =  total[lid].blank? ?  1 : total[lid]+1   
        Rails.logger.debug "\nes287_debug ocnt line:(#{__LINE__}) overridden count = " + ocnt.inspect 
        tmploc["location_name"] = dispname
        #dcode = iinfo[:perm_location][:number].to_s
        tmploc["location_code"] = dcode 
        tmploc["item_enum"] = iinfo[:item_enum]
        tmploc["holding_id"] = [mid]
        tmploc["chron"] = iinfo[:chron] 
        tmploc["call_number"] = hrds[mid]["callnos"][0] 
        tmploc["copies"] = iinfo[:copy_number] 
        copies = ""
        copies = " c. #{tmploc['copies']} " unless tmploc.blank?
        Rails.logger.debug "\nes287_debug #{__FILE__}:#{__LINE__} tmploc = " + tmploc.inspect 
        tmploc["display"] = Maybe(tmploc['item_enum']) + ' ' + Maybe(tmploc['chron']) + Maybe(copies) +  " Shelved in #{dispname}"
        #oneloc["summary_holdings"] = "Library has: " + summary_holdings.join(' ') unless summary_holdings.blank?
        Rails.logger.debug "\nes287_debug line(#{__LINE__}) item = " + iinfo.inspect
        Rails.logger.debug "\nes287_debug line(#{__LINE__}) tmploc = " + tmploc.inspect
        Rails.logger.debug "\nes287_debug file:#{__FILE__} line(#{__LINE__}) dispname = " + dispname.inspect
        overinfo[mid]  =   tmploc 
        if over[mid].blank?
           over[mid]  =  [ tmploc["display"] ]
        else
          over[mid] << tmploc["display"] 
         end
      end
      if (!iinfo['temp_location'].blank? && iinfo['temp_location'] != "0"  ) && iinfo['temp_location'] != hrds[mid]["locations"][0]["number"].to_s 
        Rails.logger.debug "\nes287_debug item line:(#{__LINE__} OVERRIDDEN  item temp location = " + iinfo['temp_location'].inspect
        dispname = locnames_by_lid[iinfo[:temp_location]][:display_name]
        ocnt[lid]  =  ocnt[lid].blank? ?  1 : ocnt[lid]+1   
        total[lid]  =  total[lid].blank? ?  1 : total[lid]+1   
        Rails.logger.debug "\nes287_debug ocnt line:(#{__LINE__}) overriden count = " + ocnt.inspect 
        tmploc["location_name"] = dispname
        dcode = locnames_by_lid[iinfo[:temp_location]][:location_code]
        tmploc["location_code"] = dcode 
        tmploc["holding_id"] = [mid]
        tmploc["item_enum"] = iinfo[:item_enum]
        tmploc["chron"] = iinfo[:chron] 
        tmploc["call_number"] = hrds[mid]["callnos"][0] 
        tmploc["copies"] = []
        tmploc["display"] = tmploc['item_enum'] +  ' ' + tmploc['chron'] + " Temporarily shelved in #{dispname}"
        Rails.logger.debug "\nes287_debug line(#{__LINE__}) tmploc = " + tmploc.inspect
        Rails.logger.debug "\nes287_debug line(#{__LINE__}) dispname = " + dispname
        overinfo[mid]  =   tmploc 
        if over[mid].blank?
           over[mid]  =  [ tmploc["display"] ]
        else
          over[mid] <<  tmploc["display"] 
         end
      end
    end
    Rails.logger.debug "\nes287_debug ocnt line:(#{__LINE__}) overridden count = " + ocnt.inspect 
    Rails.logger.debug "\nes287_debug total line:(#{__LINE__}) item count in holding = " + total.inspect 
    return over,overinfo
  end

  # condensed has holding info, keyed by holding id as string 
  # items is an array of hashes of item info 
  # add the item info to the condensed info
  # notes, and summary holdings are indexed by holding id to add to proper item blob in holdings list. 
  # over_locs indexed by mid -- array of holding notes, like Shelved at xxx, or Temporarily Shelved at
  # when either perm_location or temp_location in item overrides Holding location.
  #
  def parse_item_info(condensed,items,notes_by_mid,sumh_by_mid,grouped,bibid,response,over_locs,orders_by_mid)
    items_by_mid = {}
    if false 
    # needed this when condensed was organized by library name.
    # now it is keyed by holding id. 
    # condensed by holding id (mid ), to find which condensed entry contains a particular mid 
    # value  at the index is a library 'displayname'.
    condn_by_mid = {}
    condensed.each_key  do |lk| 
      Rails.logger.debug "\nes287_debug condensed key lk  = #{lk}"
      condensed[lk]["holding_id"].each  do |hk| 
        condn_by_mid[hk] = lk
      end 
    end
    end
    #condn_by_mid = create_dn_by_mid(bibid,response)
    #Rails.logger.debug "\nes287_debug line:(#{__LINE__})items this condn by mid = "+ condn_by_mid.inspect
    # TODO -- there may be notes on a holding record,
    #  but no items attached to that holding.  if that is true, this does not work.
    #  need to detect this condition, and correct for that.
    #  example bound withs, like 531286, or RMC things with no item records
    items.each do |iinfo|
      hk = iinfo['mfhd_id']
      curi = ""
      if (!condensed[hk].nil? && !condensed[hk]["current_issues"].nil?)
       curi = condensed[hk]["current_issues"]
      end
      indx = ""
      if (!condensed[hk].nil? && !condensed[hk]["indexes"].blank?)
       indx = condensed[hk]["indexes"]
      end
      supl = ""
      supl1 = ""
      supl2 = ""
      if (!condensed[hk].nil? && !condensed[hk]["supplements"].blank?)
       supl1 = condensed[hk]["supplements"]
      end
      if (!condensed[hk].nil? && !condensed[hk]["supplemental_holdings_desc"].blank?)
       supl2 = condensed[hk]["supplemental_holdings_desc"]
      end
      if (!supl1.blank? || !supl2.blank?)
       supl = "Supplements:" +supl1+supl2 
      end
      items_by_mid[hk] = {"items"=> {}, "notes"=>notes_by_mid[hk], "summary_holdings"=>sumh_by_mid[hk],
        "current_issues"=>curi,"supplements" => supl , "indexes"=> indx }
    end
    # insert item info into correct place into condensed array 
    Rails.logger.debug "\nes287_debug File:#{__FILE__}:line:#{__LINE__} items_by_mid  = #{items_by_mid.inspect}"
    Rails.logger.debug "\nes287_debug File:#{__FILE__}:line:#{__LINE__} condensed  = #{condensed.inspect}"
    items_by_mid.each_key do |hk|
      Rails.logger.debug "\nes287_debug File:#{__FILE__}:line:(#{__LINE__}) hk  = #{hk}"
      next if  hk.nil?
      next if  items_by_mid[hk].nil?
      next if  condensed[hk].nil?
      #condensed[condn_by_mid[hk]]["copies"] << items_by_mid[hk] 
      condensed[hk]["copies"] << items_by_mid[hk]  
      if !over_locs[hk].blank?
        Rails.logger.debug "\nes287_debug line:(#{__LINE__}) over_locs[hk]  = #{over_locs[hk]}"
        #condensed[condn_by_mid[hk]]["copies"][0]["temp_locations"]  = over_locs[hk] 
        condensed[hk]["copies"][0]["temp_locations"]  = over_locs[hk] 
      end
      condensed[hk]["copies"][0]["items"]  = grouped[hk]["items"] unless  grouped[hk].nil?
    end
    condensed.each_key do |hk|
      Rails.logger.debug "\nes287_debug line:(#{__LINE__}) hk  = #{hk}"
      if  condensed[hk.to_s]["copies"].blank?
        #condensed[hk.to_s]["copies"] = [{"items" =>{} ,"orders" => [] } ]  
        condensed[hk.to_s]["copies"] = 
          [{"items"=>{"Not Available"=>{"status"=>"none", "count"=>0}}, "notes"=>nil, "summary_holdings"=>nil,"orders" => nil}]
      end
      condensed[hk.to_s]["copies"][0]["orders"] =  orders_by_mid[hk.to_s] unless orders_by_mid[hk.to_s].blank? 
    end
    condensed
  end 

  # create display name by mid
  def create_dn_by_mid(bibid, response)
    dn_by_mid = {}
    if response[bibid] and response[bibid][bibid] and response[bibid][bibid][:records]
      response[bibid][bibid][:records].each do |record|
        if record[:bibid].to_s == bibid
          record[:holdings].each do |holding|
              dn_by_mid[holding[:MFHD_ID].to_s] = holding[:TEMP_LOCATION_DISPLAY_NAME].nil? ? holding[:PERM_LOCATION_DISPLAY_NAME]:holding[:TEMP_LOCATION_DISPLAY_NAME]  
          end
        end
      end
    end
    dn_by_mid
  end

  # parse the circ status response so all statuses are stored by item id.
  # parse_item_status
  def parse_item_status(bibid, response,items_solr)
    locations_by_iid = {}
    statuses_by_iid = {}
    statuses_as_text = {}
    items_by_lid = {}
    items_by_hid = {}
    orders_by_hid = {}
    if response[bibid] and response[bibid][bibid] and response[bibid][bibid][:records]
      response[bibid][bibid][:records].each do |record|
        if record[:bibid].to_s == bibid
          record[:holdings].each do |holding|
              locations_by_iid[holding[:ITEM_ID].to_s] = holding[:TEMP_LOCATION_DISPLAY_NAME].nil? ? holding[:PERM_LOCATION_DISPLAY_NAME]:holding[:TEMP_LOCATION_DISPLAY_NAME]  
              statuses_by_iid[holding[:ITEM_ID].to_s] = holding[:ITEM_STATUS].to_s  
              Rails.logger.debug "\nes287_debug line #{__LINE__} one holding = " + holding.inspect
              lk=holding[:TEMP_LOCATION_DISPLAY_NAME].nil? ? holding[:PERM_LOCATION_DISPLAY_NAME]:holding[:TEMP_LOCATION_DISPLAY_NAME]  
              hk=holding[:MFHD_ID]
              items_by_lid[lk] ||= []
              items_by_lid[lk] << holding[:ITEM_ID].to_s 
              items_by_hid[hk] ||= []
              orders_by_hid[hk.to_s] ||= []
              items_by_hid[hk] << holding[:ITEM_ID].to_s 
              statuses_as_text[holding[:ITEM_ID].to_s] = make_substitute(holding,items_solr) 
              Rails.logger.debug "\nes287_debug line #{__LINE__} is there an item id  = " + holding.inspect
              if holding[:ITEM_ID].nil? and !(holding[:ODATE].nil?)  and holding[:PO_TYPE] != 5 and holding[:DISPLAY_CALL_NO].blank?
                 Rails.logger.debug "\nes287_debug line #{__LINE__} there no item id, there is an order date so treat as order  = " + holding.inspect
                 orders_by_hid[hk.to_s] = "1 Copy Ordered as of " + holding[:ODATE].to_s[0,10]
              end
                 
          end
        end
      end
    end
  return locations_by_iid,statuses_by_iid,items_by_lid,items_by_hid,statuses_as_text,orders_by_hid
  end

  # make substitutions into status string.
  def make_substitute(holding,items_solr)
    status_text = ''
    enum =  reqs = ''
    date = sdate = ''
    enum = copy = ''
    if !holding[:ITEM_ID].nil? 
      sdate = holding[:ITEM_STATUS_DATE].to_s.slice(0,10)
      date = holding[:CURRENT_DUE_DATE].blank? ? holding[:ITEM_STATUS_DATE].to_s.slice(0,10)  : holding[:CURRENT_DUE_DATE].to_s.slice(0,10)  
      solri = items_solr[holding[:ITEM_ID].to_s]
      Rails.logger.debug "es287_debug #{__FILE__} #{__LINE__} solri = #{solri.inspect}\n"
      reqs = "0"
      if !solri.nil?
        copy = solri['copy_number'].blank? ? "" : " c. #{solri['copy_number']}"
        enum = solri['item_enum'] + ' ' + solri['chron']+copy
        reqs = solri['reqs'] 
        Rails.logger.debug "es287_debug #{__FILE__} #{__LINE__} solri = #{solri.inspect}\n"
      end
      norr = reqs == '0' ? 'n' : 'r'
      status =  ITEM_STATUS_CODES[holding[:ITEM_STATUS].to_s + norr].nil?  ?  "Status #{holding[:ITEM_STATUS].to_s} " : ITEM_STATUS_CODES[holding[:ITEM_STATUS].to_s + norr]['short_message']
      Rails.logger.debug "es287_debug #{__FILE__} #{__LINE__} status = #{status.inspect}\n"
      status_text =  status.gsub('%ENUM',enum)
      status_text =  status_text.gsub('%SDATE',sdate)
      status_text =  status_text.gsub('%DATE',date)
      status_text =  status_text.gsub('%REQS',reqs)
      status_text =  status_text.gsub('at %LOC','') # I have not figured out where to get the loc from yet.
      status_text =  status_text.gsub('to %LOC','') # I have not figured out where to get the loc from yet.
    end
  Rails.logger.debug "es287_debug #{__FILE__} #{__LINE__} status text = #{status_text.inspect}\n"
  status_text
  end

  # group item statuses together by library id 
  #   produces a hash  of statuses that look like
  #   {"Available": {"status" : "available", "count":1},"Checked out, due 2014-10-09":{"status":"not_available","count":1}}
  #   this needs to be placed in the "copies" element as the value the "items" element.
  #   The various holding ids AT the same library are collapsed
  #   Well, it turned out this should work NOT by library id, but by library display name
  #   in order to group items at the same place, though it has a different code
  #   Well, it turned out that it should be grouped by holding id, not displayname.
  #   so i had to re-rewrite again.
  def group_item_statuses(bibid,statuses_by_iid,items_by_hid,locations_by_iid)
    # grouped by hid, the statuses in array for each item at that holding id.
    grouped = {} 
    # grouped by hid, a hash of status as integer, as key, and count as value. 
    groupsc = {}
    # grouped by hid, a hash of status, as key, and count as value. 
    groupisc = {}
    # grouped by hid AS STRING, items statuses 
    groupz = {}
    # make an array by hk  with all the statuses 
    items_by_hid.each_key do | hk |  
      grouped[hk] ||= [] 
      items_by_hid[hk].each do | iid |  
        grouped[hk] << statuses_by_iid[iid]
      end
    end
    # Array of statuses, count each status 
    grouped.each_key do | hk |
      grouph = {} 
      grouped[hk].each do | sk |
      if (!sk.nil?) 
        grouph[sk] ||= 0   
        grouph[sk]  += 1   
       end
      end
      groupsc[hk] = grouph unless !grouph.size
    end
    Rails.logger.debug "\nes287_debug line:#{__LINE__} status count by hk  = "+ groupsc.inspect 
    # groupsc is indexed by hk  --
    #  has a hash of counts and statuses
    groupsc.each_key do | hk |
      grouph = groupsc[hk]
      groupisc[hk] ||=  {}
      Rails.logger.debug "\nes287_debug hk line:(#{__LINE__})  = " + hk.inspect 
      some_available = 0 
      some_not_avail = 0 

      grouph.each_key do | sk |
        if  ['Available','Returned'].any? {|code| sk.include?(code) }
          some_available = 1 
        else
          some_not_avail = 2 
        end
      end

      grouph.each_key do | sk |
        status = 
              case some_not_avail + some_available  
                   when 0  
                        "none" 
                   when 1  
                        "available" 
                   when 2
                         "not_available" 
                   when 3
                         "some_available" 
                   else
                      "not_available" 
              end
        if  ['Available','Returned'].any? {|code| sk.include?(code) }
          status = "available" ;
        end
        if !sk.blank?
          status_code = sk 
          #status_code = ITEM_STATUS_CODES[sk.to_s + 'n']['short_message']
        else
          status      = 'none'
          status_code = ' '
        end 
        Rails.logger.debug "\nes287_debug line:#{__LINE__} status numeric as string =" + sk.to_s.inspect 
        Rails.logger.debug "\nes287_debug line:#{__LINE__} status short message:"+ status_code  
        Rails.logger.debug "\nes287_debug line:#{__LINE__} some available:"+ some_available.to_s  
        Rails.logger.debug "\nes287_debug line:#{__LINE__} some not avail:"+ some_not_avail.to_s 
        groupisc[hk][status_code]={"status"=>status,"count"=>grouph[sk] } if [1,2,3].any?{|c| some_available + some_not_avail  ==  c} 
        Rails.logger.debug "\nes287_debug line:#{__LINE__} status so far #{hk}  " + groupisc[hk].inspect 
      end unless hk.nil?
    end
    groupisc.each_key do | hk |
      groupz[hk.to_s]  =  {"items" => groupisc[hk] }
    end
    groupz
  end

  def old_group_item_statuses(bibid,statuses_by_iid,items_by_lid,locations_by_iid)
    # grouped by lid, the statuses in array for each item at that library.
    grouped = {} 
    # grouped by lid, a hash of status as integer, as key, and count as value. 
    groupsc = {}
    # grouped by lid, a hash of status, as key, and count as value. 
    groupisc = {}
    # make an array by lk  with all the statuses 
    items_by_lid.each_key do | lk |  
      grouped[lk] ||= [] 
      items_by_lid[lk].each do | iid |  
        grouped[lk] << statuses_by_iid[iid]
      end
    end
    # Array of statuses, count each status 
    grouped.each_key do | lk |
      grouph = {} 
      grouped[lk].each do | sk |
      if (!sk.nil?) 
        grouph[sk] ||= 0   
        grouph[sk]  += 1   
       end
      end
      groupsc[lk] = grouph unless !grouph.size
    end
    Rails.logger.debug "\nes287_debug line:#{__LINE__} status count by library id = "+ groupsc.inspect 
    # groupsc is indexed by library id --
    #  has a hash of counts and statuses
    groupsc.each_key do | lk |
      grouph = groupsc[lk]
      groupisc[lk] ||=  {}
      Rails.logger.debug "\nes287_debug lk line:(#{__LINE__})  = " + lk.inspect 
      grouph.each_key do | sk |
        status = "not_available"
        if  ['1','11'].any? {|code| sk == code}
          status = "available";
        end
        if  ['Available','Returned'].any? {|code| sk.include?(code) }
          status = "available";
        end
        Rails.logger.debug "\nes287_debug line:#{__LINE__} status numeric as string  = " + sk.to_s.inspect 
        Rails.logger.debug "\nes287_debug line:#{__LINE__} status short message  " + ITEM_STATUS_CODES[sk.to_s + 'n']["short_message"]  
        groupisc[lk][ITEM_STATUS_CODES[sk.to_s + 'n']["short_message"]]={"status"=>status,"count"=>grouph[sk] } 
        Rails.logger.debug "\nes287_debug line:#{__LINE__} status so far #{lk}  " + groupisc[lk].inspect 
      end unless lk.nil?
    end
    groupisc.each_key do | lk |
      groupisc[lk]  =  {"items" => groupisc[lk] }
    end
    groupisc
  end

  def   fix_items(items,bibid, response) 
  # make the items array be indexed by itemid.
  items_solr = {}  
  items2 = []  
  Rails.logger.debug "\nes287_debug document items line(#{__LINE__}) =   " + items.inspect 
  items.each do |item|
    items_solr[item["item_id"]] = item
  end
  Rails.logger.debug "\nes287_debug document items3 line(#{__LINE__}) =   " + items_solr.inspect 
  items_db = {}  
  if response[bibid] and response[bibid][bibid] and response[bibid][bibid][:records]
    response[bibid][bibid][:records].each do |record|
      if record[:bibid].to_s == bibid
        record[:holdings].each do |holding|
              items_db[holding[:ITEM_ID].to_s] = holding 
        end
      end
    end
  end
  Rails.logger.debug "\nes287_debug items_db line(#{__LINE__}) =   " + items_db.inspect  
  items_db.each_key do |iid|
    if items_solr.has_key?(iid)
      Rails.logger.debug "\nes287_debug items_solr[iid] #{__FILE__} line(#{__LINE__}) =   " + items_solr[iid].inspect  
    end
    if !iid.nil?  && !items_solr.has_key?(iid)
      items_solr[iid] = {}
      items_solr[iid]["mfhd_id"] = items_db[iid]["MFHD_ID"].to_s  
      items_solr[iid]["item_id"] = iid.to_s  
      items_solr[iid]["call_number"] = items_db[iid]['DISPLAY_CALL_NO']
      items_solr[iid]["chron"] = ' ';   
      items_solr[iid]["item_enum"] = ' ';   
      items_solr[iid]["copies"] = ' ';   
    end
    if items_solr.has_key?(iid)
      Rails.logger.debug "\nes287_debug items_db iid #{__FILE__} line(#{__LINE__}) =   " + iid.inspect  
      Rails.logger.debug "\nes287_debug items_db[iid] #{__FILE__} line(#{__LINE__}) =   " + items_db[iid].inspect  
      items_solr[iid]["temp_location"] = items_db[iid]["TEMP_LOCATION_ID"].to_s  unless items_db[iid]["TEMP_LOCATION_ID"].to_s.blank? 
      items_solr[iid]["temp_location_display_name"] = items_db[iid]["TEMP_LOCATION_DISPLAY_NAME"].to_s  unless items_db[iid]["TEMP_LOCATION_ID"].to_s.blank? 
      items_solr[iid]["temp_location_code"] = items_db[iid]["TEMP_LOCATION_CODE"].to_s  unless items_db[iid]["TEMP_LOCATION_ID"].to_s.blank? 
      items_solr[iid]["perm_location"] = items_db[iid]["PERM_LOCATION"].to_s 
      items_solr[iid]["perm_location_display_name"] = items_db[iid]["PERM_LOCATION_DISPLAY_NAME"] 
      items_solr[iid]["perm_location_code"] = items_db[iid]["PERM_LOCATION_CODE"] 
      items_solr[iid]["current_due_date"] = (items_db[iid]["CURRENT_DUE_DATE"].nil? )  ?  ''  :  items_db[iid]["CURRENT_DUE_DATE"].to_s
      rcp = items_db[iid]["RECALLS_PLACED"].nil? ? 0 :  items_db[iid]["RECALLS_PLACED"]  
      hop = items_db[iid]["HOLDS_PLACED"].nil? ? 0 :  items_db[iid]["HOLDS_PLACED"]  
      items_solr[iid]["reqs"] = (hop+rcp).to_s
      if items_solr[iid]["chron"].blank?   
        items_solr[iid]["chron"] = ' ';   
      end
      if items_solr[iid]["item_enum"].blank?   
        items_solr[iid]["item_enum"] = ' ';   
      end
    end
  end
  Rails.logger.debug "\nes287_debug document response by iid line(#{__LINE__}) =   " + items_db.inspect 
  items_db.each_key do |iid|
    if items_solr.has_key?(iid)
      items2 << items_solr[iid]
    else
      items2 << items_db[iid]
    end
  end
  Rails.logger.debug "\nes287_debug reflattened solr line(#{__LINE__}) =   " + items2.inspect 
  return items2,items_solr
  end

  # Get rid of unnecessary avail statuses
  # condensed is an array of hashes
  def trim_avail(condensed)
  condensed.each do |loc|
      Rails.logger.debug "\nes287_debug line(#{__LINE__}) copies  =   " + loc["copies"].count.inspect  
      Rails.logger.debug "\nes287_debug line(#{__LINE__}) copies  =   " + loc["copies"].inspect  
      Rails.logger.debug "\nes287_debug line(#{__LINE__}) copies [0] items keys count =   " + loc["copies"][0]["items"].keys.count.inspect  
      Rails.logger.debug "\nes287_debug line(#{__LINE__}) copies [0] items =   " + loc["copies"][0]["items"].inspect  
      if loc["copies"][0]["items"].keys.count  > 1 &&  loc["copies"][0]["items"].has_key?('Available')  
        Rails.logger.debug "\nes287_debug line(#{__LINE__}) available exists with more than one status,so we will remove it as unnecessary." 
        loc["copies"][0]["items"].delete_if {|key, value| key == "Available" }
      end
  end
  condensed
  end

  # if there are notes on the holding record, but there are no item records,
  # we need to copy the holding note fields to the copies array
  def fix_notes(condensed)
  condensed.each do |loc|
    Rails.logger.debug "\nes287_debug line(#{__LINE__}) location=#{loc['location_name']} #{loc['call_number']}\n"  
    Rails.logger.debug "\nes287_debug line(#{__LINE__}) copies  =   " + loc["copies"][0].count.inspect  
    if !loc["copies"][0]["items"]["Not Available"].blank? and loc["copies"][0]["items"]["Not Available"]["status"] == 'none'    
      Rails.logger.debug "\nes287_debug line(#{__LINE__}) seems like there are no items, so copy notes,etc." 
      ['orders','summary_holdings','supplements','indexes','notes',
         'reproduction_note','current_issues'].each do |type|
        loc["copies"][0][type] =  loc[type]  unless loc[type].blank?    
      end
    end
  end 
  condensed
  end

  # when all items on holding have the same item perm location, 
  # and it is different from the holding perm location
  # rejigger the item perm location to be the 
  # perm location 
  # use the temp location from the response though, not from the item record, as that
  # might be out of date.
  def fix_permtemps(bibid,con_full,response)
    Rails.logger.debug "\nes287_debug #{__method__.to_s}: #{__FILE__} line(#{__LINE__}) con_full=#{con_full.inspect}\n"
    Rails.logger.debug "\nes287_debug #{__method__.to_s}: #{__FILE__} line(#{__LINE__}) response=#{response.inspect}\n"
    if @document.nil?
      iarray = nil
    else
      Rails.logger.debug "\nes287_debug fix_perm: #{__FILE__} line(#{__LINE__}) @document.item_record_display=#{@document['item_record_display'].inspect}\n"  
      iarray = @document['item_record_display']      
    end
    items = []
    if iarray.nil? 
      return con_full
    end
    Rails.logger.debug "\nes287_debug fix_perm: #{__FILE__} line(#{__LINE__}) iarray=#{iarray.inspect}\n"  
    iarray.each do |ite|
      items << JSON.parse(ite)
    end 
    Rails.logger.debug "\nes287_debug fix_perm: #{__FILE__} line(#{__LINE__}) items=#{items}\n"  
    Rails.logger.debug "\nes287_debug fix_perm: #{__FILE__} line(#{__LINE__}) items=#{items}\n"  
    # from response create an array of items similar to that of solr 
    items_db = []  
    if response[bibid] and response[bibid][bibid] and response[bibid][bibid][:records]
     response[bibid][bibid][:records].each do |record|
      if record[:bibid].to_s == bibid
        record[:holdings].each do |hdb|
              hso = {} 
              hso['mfhd_id'] = hdb['MFHD_ID'].to_s
              hso['item_id'] = hdb['ITEM_ID'].to_s
              hso['perm_location'] = {} 
              hso['perm_location']['number'] = hdb['PERM_LOCATION']
              hso['perm_location']['code'] = hdb['PERM_LOCATION_CODE']
              hso['perm_location']['name'] = hdb['PERM_LOCATION_DISPLAY_NAME']
              hso['perm_location']['library'] = hdb['PERM_LOCATION_DISPLAY_NAME']
	      if hdb['TEMP_LOCATION_ID'] != 0
                   hso['temp_location'] = {} 
                   hso['temp_location']['code'] = hdb['TEMP_LOCATION_CODE']
                   hso['temp_location']['number'] = hdb['TEMP_LOCATION_ID']
                   hso['temp_location']['name'] = hdb['TEMP_LOCATION_DISPLAY_NAME']
                   hso['temp_location']['library'] = hdb['TEMP_LOCATION_DISPLAY_NAME']
              end
              items_db << hso 
        end
      end
     end
    end
#es287_debug fix_perm: /libweb/dev/git-src/wtf/blacklight-cornell-dev2/app/helpers/cornell_catalog_helper.rb line(756) items=[{"sensitize"=>"Y", "spine_label"=>"", "magnetic_media"=>"N", "recalls_placed"=>"0", "temp_location"=>{"code"=>"uris,res", "number"=>132, "name"=>"Uris Library Reserve", "library"=>"Uris Library"}, "item_barcode"=>"31924009465034", "historical_browses"=>"12", "item_enum"=>"", "item_sequence_number"=>"1", "historical_charges"=>"55", "create_date"=>"2000-05-31 00:00:00.0", "copy_number"=>"1", "create_location_id"=>"0", "mfhd_id"=>"881500", "short_loan_charges"=>"0", "chron"=>"", "reserve_charges"=>"0", "year"=>"", "modify_location_id"=>"188", "media_type_id"=>"0", "create_operator_id"=>"", "historical_bookings"=>"0", "holds_placed"=>"0", "perm_location"=>{"code"=>"olin", "number"=>99, "name"=>"Olin Library", "library"=>"Olin Library"}, "modify_date"=>"2014-09-26 20:23:03.0", "temp_item_type_id"=>"26", "caption"=>"", "on_reserve"=>"N", "pieces"=>"1", "item_type_id"=>"3", "price"=>"0", "item_type_name"=>"book", "item_id"=>"1914113", "freetext"=>"", "modify_operator_id"=>"tbs23"}]


#es287_debug fix_permtemps: /libweb/dev/git-src/wtf/blacklight-cornell-dev2/app/helpers/cornell_catalog_helper.rb line(768) items_db=[{"BIB_ID"=>723323, "MFHD_ID"=>881500, "ITEM_ID"=>1914113, "ITEM_STATUS"=>1, "DISPLAY_CALL_NO"=>"PR115 .G46", "LOCATION_ID"=>99, "LOCATION_CODE"=>"olin", "LOCATION_DISPLAY_NAME"=>"Olin Library", "OQUANTITY"=>nil, "ODATE"=>nil, "LINE_ITEM_STATUS"=>nil, "LINE_ITEM_ID"=>nil, "TEMP_LOCATION_DISPLAY_NAME"=>nil, "TEMP_LOCATION_CODE"=>nil, "TEMP_LOCATION_ID"=>0, "ITEM_STATUS_DATE"=>"2014-12-27T08:39:17-05:00", "PERM_LOCATION"=>99, "PERM_LOCATION_DISPLAY_NAME"=>"Olin Library", "PERM_LOCATION_CODE"=>"olin", "CURRENT_DUE_DATE"=>nil, "HOLDS_PLACED"=>0, "RECALLS_PLACED"=>0, "PO_TYPE"=>nil}]


    Rails.logger.debug "\nes287_debug #{__method__.to_s}: #{__FILE__} line(#{__LINE__}) items_db=#{items_db.inspect}\n"
    # for each holding record, count the items 
    cond2 = []
    items2 = Marshal.load( Marshal.dump(items) )
    con_full.each do |loc|
      loc2 = loc
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) location=#{loc.inspect}\n"  
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) location=#{loc['location_name']} callnumber=#{loc['call_number']} holding_id=#{loc['holding_id'][0]}\n"  
      #select from items array those with matching mfhd_id, and count them. how many items on this mfhd?
      # we have to check against data directly from the db as solr might be out of date.
      im = items_db.select {|i| i['mfhd_id'] == loc['holding_id'][0] }
      imc = im.count
      im2 = items2.select {|i| i['mfhd_id'] == loc['holding_id'][0] }
      imc2 = im2.count
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items matching=#{im.inspect} and count for this holding = #{im.count}\n"  
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items2matching=#{im2.inspect} and count for this holding = #{im2.count}\n"  
      tm = im.select {|i| i['temp_location'] && !i['temp_location']['code'].blank? }
      pm = im2.select {|i| !i['perm_location']['code'].blank? }
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items matching temp=#{tm.inspect} and count with temps= #{tm.count}\n"  
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items matching perm=#{pm.inspect} and count with perms= #{pm.count}\n"  
      pl = (pm.select {|i| !i['perm_location']['code'].blank?  }).each{|x| x.keep_if{|k,v| k== 'perm_location'}}
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) pl=#{pl.inspect}\n"  
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items matching=#{im.inspect} and count for this holding = #{im.count}\n"  
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items2matching=#{im2.inspect} and count for this holding = #{im2.count}\n"  
      tl = (tm.select {|i| !i['temp_location']['code'].blank?  }).each{|x| x.keep_if{|k,v| k== 'temp_location'}}
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) tl=#{tl.inspect}\n"  
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items matching=#{im.inspect} and count for this holding = #{imc}\n"  
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items2matching=#{im2.inspect} and count for this holding = #{imc2}\n"  
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) pm count=#{pm.count} and count for this holding = #{imc2}\n"  
      #select from items array those with matching mfhd_id and a temp loc, and count them. how many items on this mfhd with a temp location?
      if pm.count > 0 and pm.count == imc2 and tm.count == 0 
        loc2['location_name'] = pl[0]['perm_location']['name'] 
        loc2['location_code'] = pl[0]['perm_location']['code'] 
        loc2['copies'][0].delete('temp_locations')
         Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) over rode based on pm pmcount = #{imc2}\n"  
      end
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) tm count=#{tm.count} and count for this holding = #{imc}\n"  
      if tm.count > 0 and tm.count == imc  
        loc2['location_name'] = tl[0]['temp_location']['name'] 
        loc2['location_code'] = tl[0]['temp_location']['code'] 
        loc2['copies'][0].delete('temp_locations')
         Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) over rode based on tm pmcount = #{imc}\n"  
      end
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) loc2=#{loc2.inspect}\n"  
      cond2 << loc2 
    end
    Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) cond2=#{cond2.inspect}\n"  
    cond2 
  end
  # when all items on holding have the same temp location, 
  # rejigger the temp location to be the 
  # perm location 
  def fix_temps(con_full)
    Rails.logger.debug "\nes287_debug fix_temp: #{__FILE__} line(#{__LINE__}) con_full=#{con_full.inspect}\n"
    if @document.nil?
      iarray = nil
    else
      Rails.logger.debug "\nes287_debug fix_temp: #{__FILE__} line(#{__LINE__}) @document.item_record_display=#{@document['item_record_display'].inspect}\n"  
      iarray = @document['item_record_display']      
    end
    items = []
    if iarray.nil? 
      return con_full
    end
    iarray.each do |ite|
      items << JSON.parse(ite)
    end 
    Rails.logger.debug "\nes287_debug fix_temp: #{__FILE__} line(#{__LINE__}) items=#{items}\n"  
  # for each holding record, count the items 
    cond2 = []
    con_full.each do |loc|
      loc2 = loc
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) location=#{loc['location_name']} callnumber=#{loc['call_number']} holding_id=#{loc['holding_id'][0]}\n"  
      #select from items array those with matching mfhd_id, and count them. how many items on this mfhd?
      im = items.select {|i| i['mfhd_id'] == loc['holding_id'][0] }
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items matching=#{im.inspect} and count for this holding = #{im.count}\n"  
      tm = im.select {|i| !i['temp_location']['code'].blank? }
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) items matching with temp=#{tm.inspect} and count with temps= #{tm.count}\n"  
      tl = (im.select {|i| !i['temp_location']['code'].blank?  }).each{|x| x.keep_if{|k,v| k== 'temp_location'}}
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) tl=#{tl.inspect}\n"  
      #select from items array those with matching mfhd_id and a temp loc, and count them. how many items on this mfhd with a temp location?
      if tm.count > 0 and tm.count == im.count  
        loc2['location_name'] = tl[0]['temp_location']['name'] 
        loc2['location_code'] = tl[0]['temp_location']['code'] 
        loc2['copies'][0].delete('temp_locations')
      end
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) loc2=#{loc2.inspect}\n"  
      cond2 << loc2 
    end
    Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) cond2=#{cond2.inspect}\n"  
    cond2 
  end
  # when holding records have the same location, AND call number --
  # collapse them into one location info block 
  # condensed is an array of hashes
  def collapse_locs(condensed)
    supl = ['orders','summary_holdings','supplements','indexes','notes','reproduction_note','current_issues']
    cond2 = []
    lstat = istat = []
    count_cond2 = {} 
    condensed.each do |loc|
      Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) location=#{loc['location_name']} #{loc['call_number']}\n"  
      if count_cond2["#{loc['location_name']} #{loc['call_number']}"].blank?   
        count_cond2["#{loc['location_name']} #{loc['call_number']}"] = {}  
        count_cond2["#{loc['location_name']} #{loc['call_number']}"]["count"] = 1  
        count_cond2["#{loc['location_name']} #{loc['call_number']}"]["holdings"] =  [loc]   
       else
        count_cond2["#{loc['location_name']} #{loc['call_number']}"]["count"]  += 1  
        count_cond2["#{loc['location_name']} #{loc['call_number']}"]["holdings"] <<  loc 
      end
    end
    Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) count_cond2=#{count_cond2.inspect}"  
    count_cond2.each do |key,loc|
      for i in 0..(loc['holdings'].size-1)  do
        Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) i=#{i} loc holdings i =#{loc['holdings'][i].inspect}"  
        # first one just copy data.
        if i == 0 
          cond2 << loc['holdings'][i]
          next
        else
          # update copies data -- items counts and statuses
          istat = cond2[cond2.size-1]['copies'][0]['items'].keys 
          lstat = loc['holdings'][i]['copies'][0]['items'].keys  
          bstat = (istat | lstat)
          Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) bstat=#{bstat.inspect}"  
          bstat.each do |s|
           if (!cond2[cond2.size-1]['copies'][0]['items'][s].blank? && !loc['holdings'][i]['copies'][0]['items'][s].blank? )
             cond2[cond2.size-1]['copies'][0]['items'][s]['count'] +=  loc['holdings'][i]['copies'][0]['items'][s]['count']
           end 
           if (cond2[cond2.size-1]['copies'][0]['items'][s].blank? && !loc['holdings'][i]['copies'][0]['items'][s].blank?)
             cond2[cond2.size-1]['copies'][0]['items'][s] =  loc['holdings'][i]['copies'][0]['items'][s]
           end 
          end #bstat.each
          # copy or add to supplementary data 
          supl.each do |type|
            if type == 'current_issues' 
              Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) type = 'current issues '@@@@ loc[holdings[i][type] =" + loc['holdings'][i][type].inspect
              Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) @@@@ loc[holdings[i] =" + loc['holdings'][i].inspect
            end
            if !loc['holdings'][i][type].blank? && !cond2[cond2.size-1]['copies'][0][type].blank? 
              if type == 'current_issues' 
                Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) @@@@ copying current issues  to " + cond2[cond2.size-1]['copies'][0][type].inspect
              end
              if type == 'summary_holdings'
                div = ';'
              else
                div = ';'
              end
              if !cond2[cond2.size-1]['copies'][0][type].include?(loc['holdings'][i][type])
                cond2[cond2.size-1]['copies'][0][type]  << div + loc['holdings'][i][type]
                if type == 'indexes'
                  Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) @@@@ copying #{type} " + cond2[cond2.size-1]['copies'][0][type].inspect
                  t1str = (cond2[cond2.size-1]['copies'][0][type]).gsub('Indexes: ','')
                  t1str.gsub!('; ',';')
                  t2str = t1str.split(';')
                  Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) @@@@ t2str =  " + t2str.inspect
                  t2str.sort!
                  Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) @@@@ t2str =  " + t2str.inspect
                  cond2[cond2.size-1]['copies'][0][type] = 'Indexes: ' + t2str.join(';')
                end
                if type == 'summary_holdings'
                  Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) @@@@ copying #{type} " + cond2[cond2.size-1]['copies'][0][type].inspect
                  t1str = (cond2[cond2.size-1]['copies'][0][type]).gsub('Library has: ','')
                  t1str.gsub!('<br/>','')
                  t1str.gsub!('&nbsp;','')
                  t1str.gsub!('; ',';')
                  #t2str = t1str.split(';')
                  t2str = t1str.split(div)
                  Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) @@@@ t2str =  " + t2str.inspect
                  t2str.sort!
                  Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) @@@@ t2str =  " + t2str.inspect
                  #cond2[cond2.size-1]['copies'][0][type] = ('Library has: ' + t2str.join(';')).html_safe
                  cond2[cond2.size-1]['copies'][0][type] = ('Library has: ' + t2str.join(';<br/>&nbsp;&nbsp;&nbsp;&nbsp;')).html_safe
                end
              end
            end 
            if !loc['holdings'][i][type].blank? && cond2[cond2.size-1]['copies'][0][type].blank? 
              if type == 'current_issues' 
                Rails.logger.debug "\nes287_debug #{__FILE__} line(#{__LINE__}) @@@@ copying current issues  to " + cond2[cond2.size-1]['copies'][0][type].inspect
              end
              cond2[cond2.size-1]['copies'][0][type]  = loc['holdings'][i][type]
            end 
          end #supl.each do  

        end #if i == 0
      end #for i in 0 .. loc
    end #count_cond2
    Rails.logger.debug "\nes287_debug line(#{__LINE__}) count_cond2=#{count_cond2.inspect}"  
    Rails.logger.debug "\nes287_debug line(#{__LINE__}) cond2=#{cond2.inspect}"  
    #condensed
    if false 
      cond2.each do |loc|
      if loc['copies'][0]['items']['Available'] &&  loc['copies'][0]['items']['Available'].size > 0   
       loc['copies'][0]['items'][' Available'] = loc['copies'][0]['items']['Available']
      end 
      loc['copies'][0]['items'].delete('Available')
 
    end
    end
    cond2
  end #def collapse_locs

end # End of Module

    # this logic is from the voyager_oracle_api status.rb
    # available statuses

    # 1 Not Charged
    # 11  Discharged

    # not available statuses

    # 2 Charged
    # 3 Renewed
    # 4 Overdue
    # 5 Recall Request
    # 6 Hold Request
    # 7 On Hold
    # 8 In Transit
    # 9 In Transit Discharged           no longer used but appear in records
    # 10  In Transit On Hold            no longer used but appear in records
    # 9 + 10 converted to 8 in GetHoldingsService
    # 12  Missing
    # 13  Lost--Library Applied
    # 14  Lost--System Applied
    # 18  At Bindery
    # 21  Scheduled
    # 22  In Process
    # 23  Call Slip Request
    # 24  Short Loan Request
    # 25  Remote Storage Request

    # not used to determine status in Voyager application or apis

    # 15  Claims Returned               x
    # 16  Damaged                       x
    # 17  Withdrawn                     x
    # 19  Cataloging Review             x
    # 20  Circulation Review            x

#    def determine_status(items)
#
#      return 'none' if items.has_key?('no_items')
#
#      icnt = 0  # count of items
#      ucnt = 0  # count of unavailable items
#
#      items.each_pair do |itemid,statuses|
#        icnt += 1
#        # the overwhelming majority of items have only one status
#        if statuses.length == 1
#          ucnt += 1 unless [1,11].any? {|code| statuses.include?(code)}
#        else
#          # some unavalable statuses can be in combination with 1 and 11 so we test for them first
#          if [2,3,4,5,6,7,8,9,10,12,13,14,18,21,22,23,24,25].any? {|code| statuses.include?(code)}
#            ucnt += 1
#          end
#        end
#      end
#
#      return 'none' if icnt == 0
#      return 'available' if ucnt == 0
#      return 'unavailable' if icnt == ucnt
#      return 'some_available'
#
#    end
#
#
