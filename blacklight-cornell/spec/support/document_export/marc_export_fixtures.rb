# frozen_string_literal: true

require "set"

def marc_from_xml(string)
  reader = MARC::XMLReader.new(StringIO.new(string), parser: "rexml")
  reader.each { |rec| return rec }
end

RSpec.shared_context "marc export fixtures" do
  before(:all) do
    dclass = Class.new(SolrDocument) do
      include Blacklight::Marc::DocumentExport
      include Blacklight::Document::Source::Marc
      include Blacklight::Document::Export::Endnote
      include Blacklight::Document::Export::Ris
      include Blacklight::Document::Export::EndnoteXml
      include Blacklight::Document::Export::Zotero

      attr_accessor :to_marc

      # ===============================================
      # Mirror the Solr fields the export code expects.
      # Solr format "Book" added as default to document
      # -----------------------------------------------
      def initialize(marc_xml_str)
        @atts = []
        @atts[0] = { name: "format", value: ["Book"] }
        self.to_marc = marc_from_xml(marc_xml_str)
        self["source"] = "MARC"
        self["marc_display"] = "marc_display present"
      end

      def [](key)
        if key.is_a?(Integer)
          return @atts[key]
        end
        @atts.each do |entry|
          return entry[:value] if key == entry[:name]
        end
        nil
      end

      def []=(key, value)
        @atts.each do |entry|
          next unless key == entry[:name]

          entry[:name] = key
          entry[:value] = value
          return entry[:value]
        end
        @atts << { name: key, value: value }
      end

      def setup_holdings_info(record)
        where = [""]
        if self["holdings_json"].present?
          holdings_json = JSON.parse(self["holdings_json"])
          holdings_keys = holdings_json.keys
          where = holdings_keys.collect do |key|
            holding = holdings_json[key]
            unless holding.blank? || holding["location"].blank? || holding["call"].blank?
              "#{holding["location"]["library"]}  #{holding["call"]}"
            end
          end
        end
        where
      end
    end


    # ==================================================================
    # xmldata.rb and other <bibid>.rb files from the support directory
    # supplies marcxml data for testing in all of the definitions below.
    # Individual records, generated from MARCXML
    # ------------------------------------------------------------------
    @book_record = dclass.new(book_record)
    @typical_record = dclass.new(standard_citation)
    @music_record = dclass.new(music_record)
    @dissertation_record = dclass.new(dissertation_note_xml)
    @record_without_245b = dclass.new(record1_xml)
    @three_authors_record = dclass.new(three_authors_xml)
    @record_without_authors = dclass.new(record2_xml)
    @record_with_10plus_authors = dclass.new(record3_xml)
    @year_range_record = dclass.new(year_range_xml)
    @no_date_record = dclass.new(no_date_xml)
    @section_title_record = dclass.new(section_title_xml)
    @special_contributor_record = dclass.new(special_contributor_with_author_xml)
    @record_without_citable_data = dclass.new(no_good_data_xml)
    @record_with_bad_author = dclass.new(bad_author_xml)
    @special_contributor_no_auth_record = dclass.new(special_contributor_no_author_xml)
    @record_utf8_decomposed = dclass.new(utf8_decomposed_record_xml)

    # Book records set, generated from MARCXML
    @book_recs = {}
    ids = ["1001", "1002", "393971", "1378974", "1676023", "2083900", "3261564", "3902220", "5494906", "5558811", "6146988", "6788245", "7292123", "7981095", "8069112", "8125253", "8392067", "8696757", "8867518", "8632993", "9305118", "9448862", "9496646", "9939352", "10055679"]
    ids.each do |id|
      @book_recs[id] = dclass.new(send("rec#{id}"))
      @book_recs[id]["id"] = id
      # just a stub valid only for bibid 10055679#
      @book_recs[id]["holdings_json"] = "{\"10368366\":{\"location\":{\"code\":\"mann\",\"number\":69,\"name\":\"Mann Library\",\"library\":\"Mann Library\",\"hoursCode\":\"mann\"},\"call\":\"SF98.A5 M35 2017\",\"circ\":true,\"date\":1506532638,\"items\":{\"count\":1,\"unavail\":[{\"id\":10369482,\"status\":{\"code\":{\"3\":\"Renewed\"},\"due\":1541286000,\"date\":1509719141}}]}}}"
    end

    # Solr electronic resource metadata added to some book records
    eids = ["8125253", "8696757", "8867518", "5558811"]
    eids.each do |id|
      @book_recs[id]["url_access_json"] = { url: "http://example.com" }.to_json
      @book_recs[id]["online"] = ["Online"]
    end

    # Solr format metadata modified for some records (default is "Book"
    @music_record["format"] = ["Musical Recording"]
    @book_recs["3261564"]["format"] = ["Musical Recording"]
    @book_recs["6788245"]["format"] = ["Video"]
    @dissertation_record["format"] = ["Thesis"]
    @book_recs["5494906"]["format"] = ["Thesis"]
    @book_recs["1378974"]["format"] = ["Thesis"]
    @book_recs["1676023"]["format"] = ["Map or Globe"]
  end
end
