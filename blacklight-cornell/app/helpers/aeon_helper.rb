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
  # rubocop:disable Metrics/BlockNesting
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
                c = " c. #{[item['copy'], item['enum'] || item['chron'], item['caption']].compact.join(' ')}"
              end

              d = item['caption'].nil? ? '' : " #{item['caption']}"

              holdings_hash[holding_id]['call'] ||= ''

              if item['barcode']
                if item['rmc'].nil?
                  item['rmc'] = {}
                  item['rmc']['Vault location'] = item['location'] ? "#{item['location']['code']} #{item['location']['library']}" : 'Not in record'
                end
                ret += labeled_checkbox(item['barcode'])
                if item['location']['name'].include?('Non-Circulating')
                  if item['rmc'].nil? || item['rmc']['Vault location'].nil?
                    ret += availability_text('now', b, c, item)
                    ret += itemdata_script(
                      item: item,
                      location: item['location']['code'],
                      csloc: "#{item['location']['code']} #{item['location']['library']}",
                      code: 'rmc'
                    )
                  else
                    # for requests to route into Awaiting Restriction Review,
                    # the cslocation needs both the vault and the building.
                    vault_location = item['rmc']['Vault location']
                    location_code = item['location']['code']
                    cslocation = vault_location.include?(location_code) ? vault_location : "#{vault_location} #{location_code}"
                    ret += availability_text('now', b, c, item)
                    ret += itemdata_script(
                      item: item,
                      location: vault_location,
                      csloc: cslocation,
                      code: 'rmc'
                    )
                  end
                else
                  location = if item['rmc']['Vault location'].nil?
                               item['location']['code']
                             else
                               item['rmc']['Vault location']
                              end
                  csloc = if item['rmc']['Vault location'].nil?
                            "#{item['location']['code']} #{item['location']['library']}"
                          else
                            item['rmc']['Vault location']
                          end
                  code = item['rmc']['Vault location'].nil? ? 'rmc' : item['location']['code']

                  ret += availability_text('advance', b, c, item)
                  ret += itemdata_script(
                    item: item,
                    location: location,
                    csloc: csloc,
                    code: code
                  )
                end
              else
                if item['rmc'].nil?
                  item['rmc'] = {}
                  item['rmc']['Vault location'] = item['location']['library'] || 'not in record'
                end
                item['rmc']['Vault location'] ||= ''
                ret += labeled_checkbox("iid-#{item['id']}")
                if item['location']['name'].include?('Non-Circulating')
                  item['call'] ||= ''
                  # THIS IS WHERE THE PROBLEM IS
                  ret += availability_text('now', b, c, item)
                  ret += itemdata_script(
                    item: item,
                    location: item['rmc']['Vault location'],
                    csloc: "#{item['location']['code']} #{item['rmc']['Vault location']}",
                    code: item['location']['code']
                  )
                else
                  ret += availability_text('advance', b, c, item)
                  ret += itemdata_script(
                    item: item,
                    location: item['rmc']['Vault location'],
                    csloc: item['rmc']['Vault location'],
                    code: item['location']['code']
                  )
                end
                d = ''
              end
            end
          else
            items_hash = {}
            if @document['items_json']
              count = 0
              items_hash = JSON.parse(@document['items_json'])
              # rubocop:disable Style/HashEachMethods
              items_hash.each do |_, items_array|
                if count < 1
                  items_array.each do |item|
                    item['location']['library'] = 'ANNEX' if item['location']['library'] == 'Library Annex'
                    if item['barcode']
                      item['rmc'] ||= {}
                      item['rmc']['Vault location'] ||= 'not in record'
                      ret += labeled_checkbox(item['barcode'])
                      location = item.dig('rmc', 'Vault location') || item['location']['code']
                      if item['location']['name'].include?('Non-Circulating')
                        ret += availability_text('now', item['call'], item['copy'], item)
                        ret += itemdata_script(
                          item: item,
                          location: location,
                          csloc: "#{item['location']['code']} #{item['location']['library']}",
                          code: 'rmc'
                        )
                      else
                        code = item.dig('rmc', 'Vault location') ? item['location']['code'] : 'rmc'
                        ret += availability_text('advance', item['call'], item['copy'], item)
                        ret += itemdata_script(
                          item: item,
                          location: location,
                          csloc: "#{item['location']['code']} #{item['location']['library']}",
                          code: code
                        )
                      end
                    else
                      ret += labeled_checkbox("iid-#{item['id']}")
                      availability_type = item['location']['name'].include?('Non-Circulating') ? 'now' : 'advance'
                      ret += availability_text(availability_type, item['call'], item['copy'], item)
                      ret += itemdata_script(
                        item: item,
                        location: item['rmc']['Vault location'],
                        csloc: "#{item['location']['code']} #{item['location']['library']}",
                        code: item['location']['code']
                      )
                    end
                  end
                  count += 1
                end
              end
            end
          end
          count += 1
        end
      end
    else
      items_hash = {}
      if holdings_hash
        count = 0
        items_hash = JSON.parse(@document['holdings_json'])
        #	ret = items_hash.inspect
        items_hash.each do |_, item|
          if count < 1
            item['rmc'] ||= {}
            item['rmc']['Vault location'] ||= 'not in record'
            if item['barcode']
              ret += labeled_checkbox(item['barcode'])
              if item['location']['name'].include?('Non-Circulating')
                location = item.dig('rmc', 'Vault location') || item['location']['code']
                csloc = item.dig('rmc', 'Vault location') ? item['rmc']['Vault location'] : item['location']['library']
                ret += availability_text('now', item['call'], item['copy'], item)
                ret += itemdata_script(
                  item: item,
                  location: location,
                  csloc: "#{item['location']['code']} #{csloc}",
                  code: 'rmc'
                )
              else
                ret += availability_text('advance', item['call'], item['copy'], item)
                ret += itemdata_script(
                  item: item,
                  location: item['rmc']['Vault location'],
                  csloc: "#{item['location']['code']} #{item['location']['library']}",
                  code: item['location']['code']
                )
              end
            elsif item['location']['name'].include?('Non-Circulating')
              ret += labeled_checkbox("iid-#{item['hrid']}")
              ret += item['location']['library'] + availability_text('now', item['call'], item['copy'], item)
              ret += itemdata_script(
                item: item,
                location: item['rmc']['Vault location'],
                csloc: "#{item['location']['code']} #{item['rmc']['Vault location']}",
                code: item['location']['code']
              )
            else
              # ret = ret + item["barcode"]
              ret += labeled_checkbox("iid-#{item['id']}")
              ret += availability_text('advance', item['call'], item['copy'], item)
              ret += itemdata_script(
                item: item,
                location: item['rmc']['Vault location'],
                csloc: "#{item['location']['code']} #{item['rmc']['Vault location']}",
                code: item['location']['code']
              )
            end
            count += 1
          end
        end
      end
    end
    ret += "<!--Producing menu with items no need to refetch data. ic=**$ic**\n -->"
    ret
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

  # Generates the availability text for a given call number, copy number, and item.
  # (Note that this method closes the div that was opened in labeled_checkbox().)
  #
  # @param availability [String] The availability of the item - 'now' or 'advance'.
  # @param call_number [String] The call number of the item.
  # @param copy_number [String] The copy number of the item.
  # @param restrictions [String] The restrictions on the item.
  # @return [String] The availability text.
  def availability_text(availability, call_number, copy_number, item)
    restrictions = item.dig('rmc', 'Restrictions') || ''
    text = availability == 'now' ? 'Available Immediately' : 'Request in Advance'
    " (#{text}) #{call_number} c #{copy_number} #{restrictions}</div>"
  end

  def itemdata_script(item:, location:, csloc:, code:)
    restrictions = item.dig('rmc', 'Restrictions') || ''
    barcode = item['barcode'] || "iid-#{item['id']}" || "iid-#{item['hrid']}"
    caption = item['rmc']['Vault location'].nil? ? '' : item['caption']
    <<~HTML
      <script>
        itemdata["#{barcode}"] = {
          location: "#{location}",
          enumeration: "#{item['enum']}",
          barcode: "#{barcode}",
          loc_code: "#{item['location']['code']}",
          chron: "",
          copy: "#{item['copy']}",
          free: "",
          caption: "#{caption}",
          spine: "",
          cslocation: "#{csloc}",
          code: "#{code}",
          callnumber: "#{item['call']}",
          Restrictions: "#{restrictions}"
        };
      </script>
    HTML
  end
end
