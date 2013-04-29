module HoldingsHelper

  def process_online_title(title)
    # Trim leading and trailing text
    # Reformat coverage dates to simply mm/yy (drop day) and wrap in span for display
    title_clean = title.to_s.gsub(/^Full text available from /, '').gsub(/(\d{1,2})\/\d{1,2}(\/\d{4})/, '\1\2').gsub(/\sConnect to full text\.$/, '').gsub(/(:\s)(\d{1,2}\/\d{4}\sto\s.{0,7})/, ' <span class="online-coverage">(\2)</span>').html_safe
    # Address the Factiva links that come with a lengthy note
    title_clean.to_s.gsub(/(Please check resource for coverage or contact a librarian for assistance.)$/, '<span class="online-note">\1</span>').html_safe
  end

  # Group holding items into circulating and rare (sort rare last)
  def group_holdings holdings
    holdings.inject({}) do |grouped, holding|
      grouped['Circulating'] = [] if grouped['Circulating'].nil?
      grouped['Rare'] = [] if grouped['Rare'].nil?
      if holding['location_code'].include?('rmc')
        grouped['Rare'] << holding
      else
        grouped['Circulating'] << holding
      end
      # Remove empty groups (no holdings)
      grouped.select! { |group, items| items.present? }
      # Sort groups by key so rare is last
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

end

