module CornellHoldingsHelper

  def holdings_as_text(document)
    holdings_text = ''
    holdings_text += online_display(document)
    circulating_items,online_items,rare_items = group_holdings(document)
    if !circulating_items.blank?
      items = circulating_items.sort_by { |e| e["location"]["name"]  }
      group = "Circulating"
      holdings_text = group_as_text(group,document,items)
    end
    if !rare_items.blank?
      items = rare_items.sort_by { |e| e["location"]["name"]  }
      group = "Rare"
      holdings_text += "\nRare Items" if circulating_items.present?
      holdings_text += group_as_text(group,document,items)
    end
    holdings_text
  end

  # Group holdings into circulating, online, and rare item.
  def group_holdings(document)
    holdings = JSON.parse(document['holdings_json'])
    Rails.logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} holdings  = #{holdings.inspect}"
    circulating_items = []
    rare_items = []
    online_items = []
    # handle separate sets
    holdings.each do |k,holding|
     if holding["location"].present?
       if holding["location"]["name"].include?('Rare') 
         rare_items << holding 
       else 
         circulating_items << holding 
        end 
     elsif holding["online"].present? 
       online_items << holding 
      end 
    end 
  [circulating_items,online_items,rare_items]
  end

  # Given a document, and set of items, return text.
  def group_as_text(group,document,items)
    output = ''
    reading = ''
    bwith = ''
    if document['bound_with_json']
      bwith = t('blacklight.catalog.bound_with')
    end
    multi_vol = document['multivol_b']
    on_site_count = 0
    reserve_item = false
    noncirc = false
    aeon_codes = []
    not_spif = 0 
    spif = 0 
    pda = 'no'
    if group == "Rare"
      reading = ' for Reading Room Delivery'
      noncirc = true 
    end
    items.each do |i|
      if group == "Rare"
        aeon_codes << i['location']['code'] unless aeon_codes.include?(i['location']['code'])
      end
      if !i["circ"].present?
      noncirc = true
      end
      reserve_item = (i['location']['code'].include?(',res') ||  i['location']['code'].include?('oclc,afrp') || i['location']['name'].include?('Reserve'))
      if i["location"]["name"] !~ /Spacecraft Planetary Imaging Facility/
        not_spif += 1 
      end
      if i["location"]["name"] =~ /Non-Circulating/
        noncirc = true 
      end
      if i["location"]["name"] =~ /Spacecraft Planetary Imaging Facility/
        noncirc = true 
        spif += 1 
      end
      if !i["call"].blank? && !i["call"].include?('No call number') && i["call"] == ' Available for the Library to Purchase'
          pda = 'yes'
      end
      if pda == 'yes'
        output += "\n" + i["call"]
      elsif i["location"]["name"] != 'Library Technical Services Review Shelves' && !document['url_pda_display'].present?
        output += "\n" + i["location"]["name"]
      end
      if !i["call"].blank? && !i["call"].include?('No call number') && i["call"] == ' Available for the Library to Purchase'
        pda = 'yes'
      end
      if !i["call"].blank? && !i["call"].include?('No call number') && i["call"] != ''
        if pda != 'yes'
            output += "\n" + i["call"]
            end
      end
      if i["items"].present?
        if i['items']['tempLoc'].present?
          i['items']['tempLoc'].each do |t|
            output += "\n" + t['enum']  + "Temporarily shelved in " + t['location']['name']
          end
        end
      end
      if i['boundWith'].present?
         bw = i['boundWith']
         bwenums = []
         bw.each do |k,v|
           @mi = v['masterBibId']
           @mt = v["masterTitle"]
           bwenums << v["masterEnum"]
         end
         output += "This item is bound with another item. Requests must be made to that item: #{@mt}"
                    + bwenums.join(', ')
      end
      if i['order'].present?
        output += "\n" + i['order']
      end
      if i['holdings'].present?
        libhas = i['holdings'].join("\n")
        output += "\n" + "Library has: #{libhas}"
      end
      if i['indexes'].present?
        indexes = i['indexes'].join("\n")
        output += "\n" + "Indexes: #{indexes}"
      end
      if i['supplements'].present?
        supplements = i['supplements'].join("\n")
        output += "\n" + "Supplements: #{supplements}"
      end
      if i['notes'].present?
        notes = i['notes'].join("\n")
        output += "\n" + "Notes: #{notes}"
      end
      if !i['recents'].nil? && i['recents'].size == 1
        current = i['recents'][0]
        output += "\n" + "Current Issues: #{current}"
      elsif  !i['recents'].nil? && i['recents'].size > 1
        current = i['recents'].join("\n")
        output += "\n" + "Current Issues: #{current}"
      end
      istatus = solr_status(i,noncirc,pda)
      output += istatus unless istatus.nil?
    end
  output
  end ### end of function

def solr_status(i,noncirc,pda)
  result = ''
  Rails.logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} i = #{i.inspect}"
  if i['avail'].present? && !i['items'].present? && !pda.present? && !i["order"].present? && i["call"] != "On Order"
      result += I18n.t('blacklight.catalog.available')
      result += I18n.t('blacklight.catalog.on_site')
  end
  if i['items'].present?
    if i['items']['avail'].present? && i['items']['avail'] == i['items']["count"] && noncirc == false 
      result += I18n.t('blacklight.catalog.available')
      result += " c. #{i['copy']}"if i['copy'].present?
      result += "Returned" + Time.at(i['items']['returned'][0]['status']['date']).strftime("%m/%d/%y") if i['items']['returned'].present?
    elsif (i['items']['avail'].present? && i['items']['avail'] == i['items']["count"] && noncirc == true)
      result += ' ' + I18n.t('blacklight.catalog.available')
      result += ' ' + I18n.t('blacklight.catalog.on_site')
    elsif i['items']['unavail'].present? 
      i['items']['unavail'].each do |item|
        if item['boundWith'] == true
           item['status'] = {}
           item['status'] = i['boundWith']["#{item["id"]}"]['status']
        end
       if !item['status'].nil?
          if item['enum'].present? 
            result += item['enum']
          end
          if i['copy'].present? 
            result += " c. #{i['copy']}"
          end
          if item['status']['code'].present?
            if item['status']['code'].keys[0] == "2" || item['status']['code'].keys[0] == "3" || item['status']['code'].keys[0] == "4"
              result += ' Checked out, due '
              if item['status']["shortLoan"].present?
                result += ' ' + Time.at(item['status']['due']).strftime("%m/%d/%y, %l:%M %P")
              else
                result += ' ' + Time.at(item['status']['due']).strftime("%m/%d/%y")
              end
            elsif item['status']['code'].keys[0] == "9" || item['status']['code'].keys[0] == "10"
              result += 'In transit ' + Time.at(item['status']['date']).strftime("%m/%d/%y")
            elsif item['status']['code'].keys[0] == "12"
              result += 'Missing ' + Time.at(item['status']['date']).strftime("%m/%d/%y")
            elsif item['status']['code'].keys[0] == "23"|| item['status']['code'].keys[0] == "25"
              result += 'Requested' + Time.at(item['status']['date']).strftime("%m/%d/%y")
            elsif item['status']['code'].keys[0] == "18"
              result += item['status']['code'].values[0] + Time.at(item['status']['date']).strftime("%m/%d/%y")
            elsif item['status']['code'].keys[0] == "7" || item['status']['code'].keys[0] == "6"
              result += item['status']['code'].values[0]
            else
              result += ' Unavailable ' + Time.at(item['status']['date']).strftime("%m/%d/%y")
            end
        end
        if item['recalls'].present? || item['holds'].present?
          item['recalls'] = 0 unless item['recalls'].present? 
          item['holds'] = 0 unless item['holds'].present? 
          total = item['holds'] + item['recalls']
          result += "(Requests: #{total})"
        end
      end
    end
    if i['items']['avail'].present? && i['items']['avail'] != i['items']['count']
      some_av = 'yes'
    end
    if some_av == 'yes' 
          result += ' ' + I18n.t('blacklight.catalog.available') + ' ' 
          result += ' All other volumes/copies'
    end
  end
  end
  if i['order'].present? 
      result += I18n.t('blacklight.catalog.on_order')
  end
  result
end
  def online_display(document)
    Rails.logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} document = #{document.inspect}"
    result = ''
    if document['url_access_json'].present?
      result += "\nOnline\n"
      document['url_access_json'].each do |link|
        Rails.logger.info "es287_debug #{__FILE__}:#{__LINE__}:#{__method__} link = #{link.inspect}"
        l = JSON.parse(link)
        if l['description'].present?
          label = l['description']
          result += "#{label}: "
        end
        result += " #{l['url']}"
       end
    end
    result
  end


end ### end of module
