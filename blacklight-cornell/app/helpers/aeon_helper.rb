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

    res = xholdings(holdings_json_hash, items_json_hash)
    Rails.logger.debug res
    res
  end

  def xholdings(holdings_hash, items_hash)
    Rails.logger.debug "mjc12: holdings_hash: #{holdings_hash}"
    Rails.logger.debug "mjc12:items_hash: #{items_hash}"

    ret = items_hash.present? ? process_items_hash(items_hash) : process_holdings_hash(holdings_hash)

    ret += "<!--Producing menu with items no need to refetch data. ic=**$ic**\n -->"
    ret
  end

  def process_items_hash(items_hash)
    # items_hash = JSON.parse(document['items_json'] || '{}')
    ret = ''
    holding_id = items_hash.keys.first
    items = items_hash[holding_id]

    copy_string = ''
    if items.present?
      items.each do |item|
        loc_code = item.dig('location', 'code')
        next unless loc_code&.include?('rmc') || loc_code&.include?('rare')

        item['location']['library'] = 'ANNEX' if item['location']['library'] == 'Library Annex'
        item['rmc'] ||= {}
        call_number = item['call'].to_s.sub('Archives ', '')
        copy_string = " c. #{[item['copy'], item['enum'] || item['chron'], item['caption']].compact.join(' ')}" if item['copy']
        item_id = item['barcode'] || "iid-#{item['id']}"
        location = item.dig('rmc', 'Vault location') || item['location']['code']

        ret += labeled_checkbox(item_id)
        ret += availability_text(call_number, copy_string, item)

        if item['barcode']
          item['rmc']['Vault location'] = item['location'] ? "#{item['location']['code']} #{item['location']['library']}" : 'Not in record'

          if item['location']['name'].include?('Non-Circulating')
            # Barcode, noncicrulating
            if item.dig('rmc', 'Vault location').nil?
              ret += itemdata_script(
                item: item,
                location: location,
                csloc: "#{item['location']['code']} #{item['location']['library']}",
                code: 'rmc'
              )
            else
              # for requests to route into Awaiting Restriction Review,
              # the cslocation needs both the vault and the building.
              vault_location = item['rmc']['Vault location']
              location_code = item['location']['code']
              cslocation = vault_location.include?(location_code) ? vault_location : "#{vault_location} #{location_code}"
              ret += itemdata_script(
                item: item,
                location: location,
                csloc: cslocation,
                code: 'rmc'
              )
            end
          else
            # Barcode, circulating
            csloc = if item['rmc']['Vault location'].nil?
                      "#{item['location']['code']} #{item['location']['library']}"
                    else
                      item['rmc']['Vault location']
                    end
            code = item['rmc']['Vault location'].nil? ? 'rmc' : item['location']['code']

            ret += itemdata_script(
              item: item,
              location: location,
              csloc: csloc,
              code: code
            )
          end
        else
          # No barcode
          ret += itemdata_script(
            item: item,
            location: item['rmc']['Vault location'] ||= '',
            csloc: "#{item['location']['code']} #{item['rmc']['Vault location']}",
            code: item['location']['code']
          )
        end
      end
    # NOTE: Because of the way items_hash is defined coming in, the following code is never reached -- I think!
    # Because items_hash = JSON.parse(document['items_json'] || '{}') (as defined in AeonRequest#initialize).

    # else
    #   Rails.logger.debug 'mjc12: !!!!!!!!!!!!!!!!!!!!!items_hash is empty'
    #   if @document['items_json']
    #     count = 0
    #     items_hash = JSON.parse(@document['items_json'])
    #     # rubocop:disable Style/HashEachMethods
    #     items_hash.each do |_, items_array|
    #       if count < 1
    #         items_array.each do |item|
    #           item['location']['library'] = 'ANNEX' if item['location']['library'] == 'Library Annex'
    #           if item['barcode']
    #             item['rmc'] ||= {}
    #             item['rmc']['Vault location'] ||= 'not in record'

    #             ret += labeled_checkbox(item['barcode'])
    #             location = item.dig('rmc', 'Vault location') || item['location']['code']
    #             csloc = "#{item['location']['code']} #{item['location']['library']}"
    #             code = if item['location']['name'].include?('Non-Circulating')
    #                       'rmc'
    #                     else
    #                       item.dig('rmc', 'Vault location') ? item['location']['code'] : 'rmc'
    #                     end

    #             ret += availability_text(item['call'], item['copy'], item)
    #             ret += itemdata_script(
    #               item: item,
    #               location: location,
    #               csloc: "#{item['location']['code']} #{item['location']['library']}",
    #               code: 'rmc'
    #             )
    #           else
    #             ret += labeled_checkbox("iid-#{item['id']}")
    #             ret += availability_text(item['call'], item['copy'], item)
    #             ret += itemdata_script(
    #               item: item,
    #               location: item['rmc']['Vault location'],
    #               csloc: "#{item['location']['code']} #{item['location']['library']}",
    #               code: item['location']['code']
    #             )
    #           end
    #         end
    #         count += 1
    #       end
    #     end
    # end
    end
    ret
  end

  def process_holdings_hash(holdings_hash)
    return '' unless holdings_hash.present?

    ret = ''
    items_hash = JSON.parse(@document['holdings_json'])
    item = items_hash.values.first

    item_id = if item['barcode']
                item['barcode']
              elsif item['location']['name'].include?('Non-Circulating')
                item['hrid']
              else
                item['id']
              end
    item['rmc'] ||= {}
    item['rmc']['Vault location'] ||= 'not in record'
    location = item['rmc']['Vault location']
    csloc_prefix = item['location']['code']
    csloc_suffix = item['rmc']['Vault location']

    ret += labeled_checkbox(item_id)
    if item['barcode']
      code = item['location']['name'].include?('Non-Circulating') ? 'rmc' : item['location']['code']

      ret += availability_text(item['call'], item['copy'], item)
      ret += itemdata_script(
        item: item,
        location: location,
        csloc: "#{csloc_prefix} #{csloc_suffix}",
        code: code
      )
    else
      ret += item['location']['library'] if item['location']['name'].include?('Non-Circulating')
      ret += availability_text(item['call'], item['copy'], item)
      ret += itemdata_script(
        item: item,
        location: location,
        csloc: "#{csloc_prefix} #{csloc_suffix}",
        code: item['location']['code']
      )
    end
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
  # The basic logic for availability is as follows:
  # - If the item is non-circulating, it is available immediately.
  # - If the item is circulating, it must be requested in advance.
  #
  # @param call_number [String] The call number of the item.
  # @param copy_number [String] The copy number of the item.
  # @param restrictions [String] The restrictions on the item.
  # @return [String] The availability text.
  def availability_text(call_number, copy_number, item)
    restrictions = item.dig('rmc', 'Restrictions') || ''
    location = item.dig('location', 'name')
    text = location&.include?('Non-Circulating') ? 'Available Immediately' : 'Request in Advance'
    " (#{text}) #{call_number} c #{copy_number} #{restrictions}</div>"
  end

  # Generates the itemdata <script> element for a given item.
  #
  # @param item [Hash] The item data.
  # @param location [String] The location of the item.
  # @param csloc [String] The CS location of the item.
  # @param code [String] The code of the item.
  # @return [String] The itemdata <script> element.
  #
  # rubocop:disable Metrics/MethodLength
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
  # rubocop:enable Metrics/MethodLength

  # Generates the hidden inputs for the Aeon request forms. This is modified from
  # the original  implementations formerly found in redirect_shib.html.erb and
  # redirect_nonshib.html.erb.
  def generate_hidden_inputs(content)
    return 'Report this error' if content.nil?

    parsed_data = JSON.parse(content.gsub('=>', ':').gsub(/\bnil\b/, 'null'))
    parsed_data.map do |key, value|
      next if key == 'Request'

      key = 'Request' if key.scan(/\D/).empty?
      tag.input(type: 'hidden', name: key, value: value)
    end.join.html_safe
  end
end
