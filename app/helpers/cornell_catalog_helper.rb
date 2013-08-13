module CornellCatalogHelper

  # Determine if user query can be expanded to WCL & Summon
  def expandable_search?
    params[:q].present? and !params[:advanced_search] and !params[:click_to_search]
  end

  def process_online_title(title)
    # Trim leading and trailing text
    # Reformat coverage dates to simply mm/yy (drop day) and wrap in span for display
    title_clean = title.to_s.gsub(/^Full text available from /, '').gsub(/(\d{1,2})\/\d{1,2}(\/\d{4})/, '\1\2').gsub(/\sConnect to full text\.$/, '').gsub(/(:\s)(\d{1,2}\/\d{4}\sto\s.{0,})/, ' <span class="online-coverage">(\2)</span>').html_safe
    # Address the Factiva links that come with a lengthy note
    title_clean.to_s.gsub(/(Please check resource for coverage or contact a librarian for assistance.)$/, '<span class="online-note">\1</span>').html_safe
  end

  # Group holding items into circulating, interwebs and rare (sort rare last)
  def group_holdings holdings
    holdings.inject({}) do |grouped, holding|
      grouped['Circulating'] = [] if grouped['Circulating'].nil?
      grouped['*Online'] = [] if grouped ['*Online'].nil?
      grouped['Rare'] = [] if grouped['Rare'].nil?
      if holding['location_code'].include?('rmc')
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

  def render_constraints_query(localized_params = params)
    # So simple don't need a view template, we can just do it here.
    if(!localized_params[:advanced_query].blank?)
      render_advanced_constraints_query(localized_params)
    else
    if (!localized_params[:q].blank?)
      localized_params[:search_field] = params["search_field"]
      label = 
        if (localized_params[:search_field].blank? )# || (default_search_field && localized_params[:search_field] == default_search_field[:key] ) )
          nil
        else
          label_for_search_field(localized_params[:search_field]) # + localized_params[:q])
#          label_for_search_field(params["search_field"] + localized_params[:q])
          
        end
      q_paramSplit = localized_params[:q].split("&")
      if q_paramSplit.count > 1
        leftSide = q_paramSplit[0].split("=")
        fixed_query = leftSide[1]
        localized_params.delete("q_row")
        localized_params.delete("boolean_row")
        localized_params.delete("op_row")
        localized_params.delete("search_field_row")
        localized_params.delete("search_field")
        localized_params.delete("sort")
        localized_params.delete("commit")
      render_constraint_element(label,
       #     localized_params[:q],
            fixed_query, 
            :classes => ["query"], 
            :remove => url_for(localized_params.merge(:q=>nil, :action=>'index')))
      else
      render_constraint_element(label,
            localized_params[:q],
      #      query, 
            :classes => ["query"], 
            :remove => url_for(localized_params.merge(:q=>nil, :action=>'index')))
#            :remove => "?") # url_for(localized_params.merge(:q=>nil, :action=>'index')))
      end
    else
      "".html_safe
    end
    end
  end



end

