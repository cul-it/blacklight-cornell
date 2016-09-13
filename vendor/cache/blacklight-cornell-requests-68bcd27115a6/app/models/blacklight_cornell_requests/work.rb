module BlacklightCornellRequests
  
  class Work
    
    attr_reader :title, :author, :isbn, :pub_info, :ill_link, :volumes
    
    # items = array of item records (usually from request2.items)
    def initialize(solrdoc, items = [])
      @title = solrdoc['title_display']
      @author = parse_author(solrdoc)
      @isbn = solrdoc['isbn_display']
      @pub_info = parse_pub_info(solrdoc)
      @ill_link = parse_ill(solrdoc)
      @volumes = parse_volumes(items)
    end
    
    def parse_author(solrdoc)
      if solrdoc['author_display'].present?
        solrdoc['author_display'].split('|')[0]
      elsif solrdoc['author_addl_display'].present?
        solrdoc['author_addl_display'].map { |author| author.split('|')[0] }.join(', ')
      else
        ''
      end
    end
    
    # Populate the publisher data fields. This can be done
    # using pub_info_display, which gloms everything together,
    # or by using the separate pubplace_display, publisher_display
    # and pub_date_display
    def parse_pub_info(solrdoc)
      solrdoc['pub_info_display'].present? ? solrdoc['pub_info_display'][0] : ''
    end
    
    def parse_ill(solrdoc)
      
      ill_link = ENV['ILLIAD_URL'] + '?Action=10&Form=30&url_ver=Z39.88-2004&rfr_id=info%3Asid%2Flibrary.cornell.edu'
      if @isbn
        isbns = @isbn.join(',')
        ill_link += "&rft.isbn=#{isbns}" + "&rft_id=urn%3AISBN%3A#{isbns}"
      end
      if @title
        ill_link += "&rft.btitle=#{CGI.escape(@title)}"
      end
      if solrdoc['author_display'].present?
        ill_link += "&rft.aulast=#{solrdoc['author_display']}"
      end

      # Populate the publisher data fields. This can be done
      # using @pub_info, which gloms everything together,
      # or by using the separate pubplace_display, publisher_display
      # and pub_date_display
      pub_date =  solrdoc['pub_date_display']  ? solrdoc['pub_date_display'][0]  : @pub_info
      publisher = solrdoc['publisher_display'] ? solrdoc['publisher_display'][0] : @pub_info
      pub_place = solrdoc['pubplace_display']  ? solrdoc['pubplace_display'][0]  : @pub_info
      ill_link += "&rft.place=#{pub_place}"
      ill_link += "&rft.pub=#{publisher}"
      ill_link += "&rft.date=#{pub_date}"

      if solrdoc['format'].present?
        ill_link += "&rft.genre=#{solrdoc['format'][0]}"
      end
      if solrdoc['lc_callnum_display'].present?
        ill_link += "&rft.identifier=#{solrdoc['lc_callnum_display'][0]}"
      end
      if solrdoc['other_id_display'].present?
        oclc = solrdoc['other_id_display'].select do |id|
          match[1] if match = id.match(/#{OCLC_TYPE_ID}([0-9]+)/)
        end
        
        if oclc.count > 0
          ill_link += "&rfe_dat=#{oclc.join(',')}"
        end
      end
      
      ill_link
      
    end
    
    # set the class volumes from a list of item records
    def parse_volumes(items) 
      
      # The map creates an array of hashes with key = :enum and value being the volume hash itself
      # VERY NAIVE - key (which serves as the text in a select list) shouldn't just be enum
      items.select {|i| i.enumeration.present? }.map { |i| {i.enumeration[:enum] => i.enumeration} }
      
    #   
    #   enum_count  = count_param(items, :enum)
    #   chron_count = count_param(items, :chron)
    #   year_count  = count_param(items, :year)
    #   
    #   # ## take first integer from each of enum, chron and year
    #   # ## if not populated, use big number to rank low
    #   # ## if the field is blank, use 'z' to rank low
    #   # ## record number of occurances for each of the 
    #   
    #   items = items.select { |i| i.enumeration.present? }
    #   
    #   items.each do |item|
    #   # 
    #     e = item.enumeration # looks like {:chron => '...', :enum => '...', :year => '...' }
    #     
    #     if e[:enum].present?
    #       enums = e[:enum].scan(/\d+/)
    #       e[:numeric_enumeration] = ''
    #       enums.each do |enum|  
    #         e[:numeric_enumeration] += enum.rjust(9,'0')  
    #       end
    #     else
    #       e[:numeric_enumeration] = '999999999'
    #     end
    #     
    #     if e[:chron].present?
    #       e[:numeric_chron]   = e[:chron][/\d+/]
    #       e[:numeric_chron]   = e[:numeric_chron].nil? ? 999999999 : e[:numeric_chron].to_i
    #     end
    #     
    #     if e[:year].present?
    #       e[:numeric_year]    = e[:year][/\d+/]
    #       e[:numeric_year]    = e[:numeric_year].nil? ? 999999999 : e[:numeric_year].to_i
    #     end
    #     
    #     e[:item_enum_compare] = e[:enum] || 'z'  
    #     e[:chron_compare]     = e[:chron] ? e[:chron].delete(' ') : 'z'
    #     e[:chron_month]       = e[:chron] ? Date::ABBR_MONTHNAMES.index(e[:chron]).to_i : 13
    #     e[:year_compare]      = e[:year] || 'z'
    # 
    #   #end
    #   
    #   ## sort based on number of occurances of each of three fields
    #   ## when tied, year has highest weight followed by enum
    #   sorted_items = {}
    #   if year_count >= enum_count && year_count >= chron_count
    #     if enum_count >= chron_count
    #       sorted_items = items.sort_by {|h| [ h.enumeration[:numeric_year],
    #                            h.enumeration[:year_compare],
    #                            h.enumeration[:numeric_enumeration],
    #                            h.enumeration[:item_enum_compare],
    #                            h.enumeration[:numeric_chron],
    #                            h.enumeration[:chron_month],
    #                            h.enumeration[:chron_compare] ]
    #                     }
    #     else
    #       sorted_items = items.sort_by {|h| [ h.enumeration[:numeric_year],
    #                            h.enumeration[:year_compare],
    #                            h.enumeration[:numeric_chron],
    #                            h.enumeration[:chron_month],
    #                            h.enumeration[:chron_compare],
    #                            h.enumeration[:numeric_enumeration],
    #                            h.enumeration[:item_enum_compare] ]
    #                     }
    #     end
    #   elsif enum_count >= chron_count and enum_count >= year_count
    #     if year_count >= chron_count
    #       sorted_items = items.sort_by {|h| [ h.enumeration[:numeric_enumeration],
    #                            h.enumeration[:item_enum_compare],
    #                            h.enumeration[:numeric_year],
    #                            h.enumeration[:year_compare],
    #                            h.enumeration[:numeric_chron],
    #                            h.enumeration[:chron_month],
    #                            h.enumeration[:chron_compare] ]
    #                     }
    #         
    #     else
    #       sorted_items = items.sort_by {|h| [ h.enumeration[:numeric_enumeration],
    #                            h.enumeration[:item_enum_compare],
    #                            h.enumeration[:numeric_chron],
    #                            h.enumeration[:chron_month],
    #                            h.enumeration[:chron_compare],
    #                            h.enumeration[:numeric_year],
    #                            h.enumeration[:year_compare] ]
    #                     }
    #     end
    #   else
    #     if year_count >= enum_count
    #       sorted_items = items.sort_by {|h| [ h.enumeration[:numeric_chron],
    #                            h.enumeration[:chron_month],
    #                            h.enumeration[:chron_compare],
    #                            h.enumeration[:numeric_year],
    #                            h.enumeration[:year_compare],
    #                            h.enumeration[:numeric_enumeration],
    #                            h.enumeration[:item_enum_compare] ]
    #                     }
    #     else
    #       sorted_items = items.sort_by {|h| [ h.enumeration[:numeric_chron],
    #                            h.enumeration[:chron_month],
    #                            h.enumeration[:chron_compare],
    #                            h.enumeration[:numeric_enumeration],
    #                            h.enumeration[:item_enum_compare],
    #                            h.enumeration[:numeric_year],
    #                            h.enumeration[:year_compare] ]
    #                     }
    #     end
    #   
    #   end
    #   
    #   sorted_items.map { |i| i.enumeration } # return the enumeration hash as the volume designation
    #   
    # end
    end
    
    # pass in the items array and an enumeration param (:chron, :year, or :enum) to get a count
    def count_param(items, param)
      items.select { |i| i.enumeration[param] if i.enumeration.present? }.count
    end

    def sort_by_param(items, param)
      items.sort_by do |a|
        [a ? 1 : 0, a]
      end
    end
    
  end
  
end