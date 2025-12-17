# -*- encoding : utf-8 -*-

require "rails_helper"

# NOTE: most of these functions and tests are copied directly from 
# the blacklight-marc gem: blacklight-marc/spec/lib/marc_export_spec.rb

def marc_from_xml(string)
  # NOTE: somewhere, one of the blacklight gems is changing the parser used by XMLReader.
  # Unless it's specified here ('rexml'), this function will fail to produce any output.
  reader = MARC::XMLReader.new(StringIO.new(string), :parser => "rexml")
  reader.each { |rec| return rec }
end

describe Blacklight::Marc::DocumentExport do
  before(:all) do

    # Mock solr document created from MARCXML for testing Marc export modules 
    dclass = Class.new(SolrDocument) do
      include Blacklight::Marc::DocumentExport
      include Blacklight::Document::Endnote
      include Blacklight::Document::Ris
      include Blacklight::Document::EndnoteXml
      include Blacklight::Document::Zotero

      attr_accessor :to_marc

      def initialize(marc_xml_str)
        @atts = []
        # Solr format "Book" added as default to document
        @atts[0] = { :name => "format", :value => ["Book"] }
        self.to_marc = marc_from_xml(marc_xml_str)
        # Mirror the Solr fields the export code expects.
        self['source'] = 'MARC'
        self['marc_display'] = "marc_display present"
      end

      def [](key)
        if key.kind_of?(Integer)
          return @atts[key]
        else
          for i in 0...@atts.length
            return @atts[i][:value] if key == @atts[i][:name]
          end
        end
        return nil
      end
  
      def []=(key, value)
        for i in 0...@atts.length
          if key == @atts[i][:name]
            @atts[i][:name] = key
            @atts[i][:value] = value
            return @atts[i][:value]
          end
        end
        @atts << { :name => key, :value => value }
      end

      def setup_holdings_info(record)
        where = [""]
        if (self["holdings_json"].present?)
          holdings_json = JSON.parse(self["holdings_json"])
          holdings_keys = holdings_json.keys
          where = holdings_keys.collect do
            |k|
            l = holdings_json[k]
            "#{l["location"]["library"]}  #{l["call"]}" unless l.blank? or l["location"].blank? or l["call"].blank?
          end
        end
        where
      end
    end

    # xmldata.rb and other <bibid>.rb files from the support directory
    # supplies marcxml data for testing in all of the definitions below.

    # Individual records, generated from MARCXML 
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
    ids = ["1001", "1002", "393971", "1378974", "1676023", "2083900", "3261564", "3902220",
           "5494906", "5558811", "6146988", "6788245", "7292123", "7981095", "8069112", "8125253",
           "8392067", "8696757", "8867518", "8632993", "9305118", "9448862", "9496646", "9939352", "10055679"]
    ids.each { |id|
      @book_recs[id] = dclass.new(send("rec#{id}"))
      @book_recs[id]["id"] = id
      # just a stub valid only for bibid 10055679#
      @book_recs[id]["holdings_json"] = "{\"10368366\":{\"location\":{\"code\":\"mann\",\"number\":69,\"name\":\"Mann Library\",\"library\":\"Mann Library\",\"hoursCode\":\"mann\"},\"call\":\"SF98.A5 M35 2017\",\"circ\":true,\"date\":1506532638,\"items\":{\"count\":1,\"unavail\":[{\"id\":10369482,\"status\":{\"code\":{\"3\":\"Renewed\"},\"due\":1541286000,\"date\":1509719141}}]}}}"
    }

    # Solr electronic resource metadata added to some book records
    eids = ["8125253", "8696757", "8867518", "5558811"]
    eids.each { |id|
      @book_recs[id]["url_access_json"] = { url: "http://example.com" }.to_json
      @book_recs[id]["online"] = ["Online"]
    }
    
    # Solr format metadata modified for some records (default is "Book")
    @music_record["format"] = ["Musical Recording"]
    @book_recs["3261564"]["format"] = ["Musical Recording"]
    @book_recs["6788245"]["format"] = ["Video"]
    @dissertation_record["format"] = ["Thesis"]
    @book_recs["5494906"]["format"] = ["Thesis"]
    @book_recs["1378974"]["format"] = ["Thesis"]
    @book_recs["1676023"]["format"] = ["Map or Globe"]
  end

  describe "export_as_openurl_ctx_kev" do
    it "should create the appropriate context object for books" do
      record = @typical_record.export_as_openurl_ctx_kev("Book")
      expect(record).to eq("ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.genre=book&amp;rft.btitle=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.title=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.au=&amp;rft.date=c2003.&amp;rft.place=Oxon%2C+U.K.+%3B&amp;rft.pub=CABI+Pub.%2C&amp;rft.edition=&amp;rft.isbn=")
      expect(record).not_to match(/.*rft.genre=article.*rft.issn=.*/)
    end
    it "should create the appropriate context object for journals" do
      record = @typical_record.export_as_openurl_ctx_kev("Journal")
      record_journal_other = @typical_record.export_as_openurl_ctx_kev("Journal/Magazine")
      expect(record).to eq("ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.genre=article&amp;rft.title=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.atitle=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.date=c2003.&amp;rft.issn=")
      expect(record_journal_other).to eq(record) and
      expect(record).not_to match(/.*rft.genre=book.*rft.isbn=.*/)
    end
    it "should create the appropriate context object for other content" do
      record = @typical_record.export_as_openurl_ctx_kev("NotARealFormat")
      expect(record).to eq("ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Adc&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.title=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.creator=&amp;rft.date=c2003.&amp;rft.place=Oxon%2C+U.K.+%3B&amp;rft.pub=CABI+Pub.%2C&amp;rft.format=notarealformat")
      expect(record).not_to match(/.*rft.isbn=.*/) and
      expect(record).not_to match(/.*rft.issn=.*/)
    end
  end

  describe "export_as_marc binary" do
    it "should export_as_marc" do
      expect(@typical_record.export_as_marc).to eq(@typical_record.to_marc.to_marc)
    end
  end

  describe "export_as_marcxml" do
    it "should export_as_marcxml" do
      expect(marc_from_xml(@typical_record.export_as_marcxml)).to eq(marc_from_xml(@typical_record.to_marc.to_xml.to_s))
    end
  end

  describe "export_as_xml" do
    it "should export marcxml as xml" do
      expect(marc_from_xml(@typical_record.export_as_xml)).to eq(marc_from_xml(@typical_record.export_as_marcxml))
    end
  end

  describe "Export as RIS  means that it " do
    it "should export a simple record correctly" do
      ris_file = @music_record.export_as_ris
      ris_entries = Hash.new { |hash, key| hash[key] = Set.new }
      ris_file.each_line do |line|
        line =~ /^(..?)  - (.*)$/
        ris_entries[$1] << $2
      end
      expect(ris_entries["TY"]).to eq(Set.new(["SOUND"]))
      expect(ris_entries["TI"]).to eq(Set.new(["Music for horn"]))
      expect(ris_entries["PY"]).to eq(Set.new(["2001"]))
      expect(ris_entries["PB"]).to eq(Set.new(["Harmonia Mundi USA"]))
      expect(ris_entries["CY"]).to eq(Set.new(["[United States]"]))
      expect(ris_entries["M2"]).to eq(Set.new(["http://catalog.library.cornell.edu/catalog/"]))
      expect(ris_entries["N1"]).to eq(Set.new(["http://catalog.library.cornell.edu/catalog/"]))
      expect(ris_entries["ER"]).to eq(Set.new([""]))
    end
    #SN  - 091316710X :
    it "should export a typical book record correctly" do
      id = "1001"
      @book_recs[id]["holdings_json"] = "{\"5195\":{\"location\":{\"code\":\"olin,anx\",\"number\":101,\"name\":\"Library Annex\",\"library\":\"Library Annex\",\"hoursCode\":\"annex\"},\"call\":\"PS591.A58 R33\",\"circ\":true,\"date\":959745600,\"items\":{\"count\":1,\"avail\":1}}}"
      ris_file = @book_recs[id].export_as_ris
      ris_entries = Hash.new { |hash, key| hash[key] = Set.new }
      ris_file.each_line do |line|
        line =~ /^(..?)  - (.*)$/
        ris_entries[$1] << $2
      end
      expect(ris_entries["TY"]).to eq(Set.new(["BOOK"]))
      expect(ris_entries["TI"]).to eq(Set.new(["Reflections: the anthropological muse"]))
      expect(ris_entries["M2"]).to eq(Set.new(["http://catalog.library.cornell.edu/catalog/1001"]))
      expect(ris_entries["PY"]).to eq(Set.new(["1985"]))
      expect(ris_entries["KW"]).to eq(Set.new(["Anthropologists' writings, American. ", "Anthropology Poetry. ", "American poetry 20th century. ", "Anthropologists' writings, English. ", "English poetry 20th century. "]))
      expect(ris_entries["PB"]).to eq(Set.new(["American Anthropological Association"]))
      expect(ris_entries["CY"]).to eq(Set.new(["Washington, D.C."]))
      expect(ris_entries["SN"]).to eq(Set.new(["091316710X  "]))
      expect(ris_entries["CN"]).to eq(Set.new(["Library Annex  PS591.A58 R33"]))
      expect(ris_entries["ER"]).to eq(Set.new([""]))
    end

    it "should export a typical ebook record correctly" do
      id = "5558811"
      @book_recs[id]["url_access_json"] = { url: "http://opac.newsbank.com/select/evans/385" }.to_json
      @book_recs[id]["language_facet"] = ["Algonquian (Other)"]
      ris_file = @book_recs[id].export_as_ris
      ris_entries = Hash.new { |hash, key| hash[key] = Set.new }
      ris_file.each_line do |line|
        line =~ /^(..?)  - (.*)$/
        ris_entries[$1] << $2
      end
      expect(ris_entries["TY"]).to eq(Set.new(["EBOOK"]))
      expect(ris_entries["AU"]).to eq(Set.new(["Company for Propagation of the Gospel in New England and the Parts Adjacent in America"]))
      expect(ris_entries["TI"]).to eq(Set.new(["Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament"]))
      expect(ris_entries["PY"]).to eq(Set.new(["1685"]))
      expect(ris_entries["PB"]).to eq(Set.new(["Printeuoop nashpe Samuel Green."]))
      expect(ris_entries["LA"]).to eq(Set.new(["Algonquian (Other)"]))
      expect(ris_entries["CY"]).to eq(Set.new(["Cambridge [Mass.]."]))
      expect(ris_entries["UR"]).to eq(Set.new(["http://opac.newsbank.com/select/evans/385"]))
      expect(ris_entries["M2"]).to eq(Set.new(["http://catalog.library.cornell.edu/catalog/#{id}"]))
      expect(ris_entries["ER"]).to eq(Set.new([""]))
    end
  end
  #

  describe "Export as endnote means that it " do
    it "should export endnote properly" do
      endnote_file = @music_record.export_as_endnote
      # We have to parse it a bit to check it.
      endnote_entries = Hash.new { |hash, key| hash[key] = Set.new }
      endnote_file.each_line do |line|
        line =~ /\%(..?) (.*)$/
        endnote_entries[$1] << $2
      end

      expect(endnote_entries["0"]).to eq(Set.new(["Music"])) # I have no idea WHY this is correct, it is definitely not legal, but taking from earlier test for render_endnote in applicationhelper, the previous version of this.  jrochkind.
      #expect(endnote_entries["D"]).to eq(Set.new(["p2001. "]))
      expect(endnote_entries["D"]).to eq(Set.new(["2001"]))
      expect(endnote_entries["C"]).to eq(Set.new(["[United States]"]))
      expect(endnote_entries["E"]).to eq(Set.new(["Greer, Lowell ", "Lubin, Steven ", "Chase, Stephanie ", "Chase, Stepehn ", "Chaste, Stepehn ", "Brahms, Johannes ", "Beethoven, Ludwig van ", "Krufft, Nikolaus von "]))
      expect(endnote_entries["I"]).to eq(Set.new(["Harmonia Mundi USA"]))
      expect(endnote_entries["T"]).to eq(Set.new(["Music for horn "]))

      #nothing extra
      #expect(Set.new(endnote_entries.keys)).to eq(Set.new(["0", "C", "D", "E", "I", "T"]))
      expect(Set.new(endnote_entries.keys)).to eq(Set.new(["0", "E", "T", "I", "C", "D", "Z", nil]))
    end
  end

  describe "Format exports" do
    it "should export the title and type in multiple formats correctly" do
      ti_ids = ["1001", "1676023", "3261564", "5494906", "5558811", "6788245"]
      ti_data = {}
      ti_output = {}
      ti_data["1001"] =
        { "endnote" => { "title" => "%T Reflections  the anthropological muse", "type" => "%0 Book" },
          "ris" => { "title" => "TI  - Reflections: the anthropological muse", "type" => "TY  - BOOK" },
          "endnote_xml" => { "title" => "<title>Reflections: the anthropological muse</title>", "type" => "<ref-type name=\"Book\">6</ref-type>" },
          "rdf_zotero" => { "title" => "<dc:title>Reflections: the anthropological muse</dc:title>", "type" => "<z:itemType>book</z:itemType>" } }
      # Sound, music
      ti_data["3261564"] =
        { "ris" => { "title" => "TI  - Debabrata Biśvāsa", "type" => "TY  - SOUND" },
          "endnote" => { "title" => "%T Debabrata Biśvāsa", "type" => "%0 Music" },
          "endnote_xml" => { "title" => "<title>Debabrata Biśvāsa</title>", "type" => '<ref-type name="Music">61</ref-type>' },
          "rdf_zotero" => { "title" => "<dc:title>Debabrata Biśvāsa</dc:title>", "type" => "<z:itemType>audioRecording</z:itemType>" } }
      #EBOOK
      ti_data["5558811"] =
        { "ris" => { "title" => "TI  - Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament", "type" => "TY  - EBOOK" },
          "endnote" => { "title" => "%T Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament", "type" => "%0 Electronic Book" },
          "endnote_xml" => { "title" => "<title>Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament</title>", "type" => "<ref-type name=\"Book\">6</ref-type>" },
          "rdf_zotero" => { "title" => "<dc:title>Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament</dc:title>", "type" => "<z:itemType>book</z:itemType>" } }
      #Thesis
      ti_data["5494906"] =
        { "ris" => { "title" => "TI  - Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700", "type" => "TY  - THES" },
          "endnote" => { "title" => "%T Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700", "type" => "%0 Thesis" },
          "endnote_xml" => { "title" => "<title>Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700</title>", "type" => "<ref-type name=\"Thesis\">32</ref-type>" },
          "rdf_zotero" => { "title" => "<dc:title>Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700", "type" => "<z:itemType>thesis</z:itemType>" } }
      ti_data["6788245"] =
        { "ris" => { "title" => "TI  - Harry Potter and the half-blood prince", "type" => "TY  - VIDEO" },
          "endnote" => { "title" => "%T Harry Potter and the half-blood prince", "type" => "%0 Film or Broadcast" },
          "endnote_xml" => { "title" => "<title>Harry Potter and the half-blood prince", "type" => "<ref-type name=\"Film or Broadcast\">21</ref-type>" },
          "rdf_zotero" => { "title" => "<dc:title>Harry Potter and the half-blood prince", "type" => "<z:itemType>videoRecording</z:itemType>" } }
      ti_data["1676023"] =
        { "ris" => { "title" => "TI  - Middle Earth: being a map", "type" => "TY  - MAP" },
          "endnote" => { "title" => "%T Middle Earth  being a map", "type" => "%0 Map" },
          "endnote_xml" => { "title" => "<title>Middle Earth: being a map", "type" => "<ref-type name=\"Map\">20</ref-type>" },
          "rdf_zotero" => { "title" => "<dc:title>Middle Earth: being a map", "type" => "<z:itemType>map</z:itemType>" } }
      ti_ids.each do |id|
        ti_output[id] = {}
        ti_output[id]["ris"] = ti_output[id]["endnote"] = ti_output[id]["endnote_xml"] = {}
        ti_output[id]["rdf_zotero"] = {}
        ti_output[id]["ris"] = @book_recs[id].export_as_ris()
        ti_output[id]["endnote"] = @book_recs[id].export_as_endnote()
        ti_output[id]["endnote_xml"] = @book_recs[id].export_as_endnote_xml()
        ti_output[id]["rdf_zotero"] = @book_recs[id].export_as_rdf_zotero()
      end
      ti_ids.each do |id|
        ["endnote", "ris", "endnote_xml", "rdf_zotero"].each do |fmt|
          ["title", "type"].each do |fld|
            expect(ti_data[id]).not_to be_nil, "You must supply data to match for bib id:#{id}."
            expect(ti_data[id][fmt]).not_to be_nil, "You must supply format data to match for bib id:#{id} for format '#{fmt}'."
            expect(ti_data[id][fmt][fld]).not_to be_nil, "You must supply field text to match for bib id:#{id}, #{fld} in format '#{fmt}' properly."
            expect(ti_output[id][fmt]).to include(ti_data[id][fmt][fld]), "For bib id:#{id},should output the #{fld} in format '#{fmt}' properly."
          end
        end
      end
    end

    #185 | 10055679 | endnote |  '%L  Mann Library  SF98.A5 M35 2017' |
    #186 | 10055679 | ris |  'CN - Mann Library  SF98.A5 M35 2017' |
    #188 | 10055679 | endnote_xml |  '<call-num>Mann Library  SF98.A5 M35 2017</call-num>' |
    #187 | 10055679 | rdf_zotero |  'Mann Library  SF98.A5 M35 2017' |
    # SN  - 9781426217661  1426217668
    # KW  - Chickens Marketing
    it "should export the call number, and isbn in multiple formats correctly" do
      ti_ids = ["10055679"]
      ti_data = {}
      ti_output = {}
      ti_ids.each do |id|
        ti_output[id] = {}
        ti_output[id]["ris"] = ti_output[id]["endnote"] = ti_output[id]["endnote_xml"] = {}
        ti_output[id]["rdf_zotero"] = {}
        expect(@book_recs[id]).not_to be_nil, "You must supply a MockMarcDocument to match for bib id:#{id}."
        ti_output[id]["ris"] = @book_recs[id].export_as_ris()
        ti_output[id]["endnote"] = @book_recs[id].export_as_endnote()
        ti_output[id]["endnote_xml"] = @book_recs[id].export_as_endnote_xml()
        ti_output[id]["rdf_zotero"] = @book_recs[id].export_as_rdf_zotero()
      end
      ti_data["10055679"] =
        { "ris" => { "callnumber" => "CN  - Mann Library  SF98.A5 M35 2017", "isbn" => "9781426217661  1426217668", "kw" => "KW  - Chickens Marketing" },
         "endnote" => { "callnumber" => "%L  Mann Library  SF98.A5 M35 2017", "isbn" => "%@ 9781426217661", "kw" => "%K Chickens Marketing" },
         "endnote_xml" => { "callnumber" => "<call-num>Mann Library  SF98.A5 M35 2017</call-num>", "isbn" => "<isbn>9781426217661  ; 1426217668 </isbn>", "kw" => "<keyword>Chickens Marketing. </keyword>" },
         "rdf_zotero" => { "callnumber" => "Mann Library  SF98.A5 M35 2017", "isbn" => Set.new(["<dc:identifier>ISBN 1426217668 </dc:identifier>", "<dc:identifier>ISBN 9781426217661 </dc:identifier>"]),
                           "kw" => "<dc:subject>Chickens Marketing. </dc:subject>" } }
      ti_ids.each do |id|
        ["ris", "endnote", "endnote_xml", "rdf_zotero"].each do |fmt|
          ["callnumber", "isbn", "kw"].each do |fld|
            expect(ti_data[id]).not_to be_nil, "You must supply data to match for bib id:#{id}."
            expect(ti_data[id][fmt]).not_to be_nil, "You must supply format data to match for bib id:#{id} for format '#{fmt}'."
            expect(ti_data[id][fmt][fld]).not_to be_nil, "You must supply field text to match for bib id:#{id}, #{fld} in format '#{fmt}' properly."
            if ti_data[id][fmt][fld].is_a? Set
              ti_data[id][fmt][fld].each { |exp|
                expect(ti_output[id][fmt]).to include(exp), "Bib id:#{id},should output #{fld} in format '#{fmt}'  did not match #{exp} properly."
              }
            else
              expect(ti_output[id][fmt]).to include(ti_data[id][fmt][fld]), "Bib id:#{id},should output the #{fld} in format '#{fmt}' properly."
            end
          end
        end
      end
    end

    it "should export the author,publisher,date,place in multiple formats correctly" do
      ti_ids = ["1378974", "3261564", "5494906", "6788245", "9496646", "9939352"]
      ti_data = {}
      ti_output = {}
      ti_ids.each do |id|
        ti_output[id] = {}
        ti_output[id]["ris"] = ti_output[id]["endnote"] = ti_output[id]["endnote_xml"] = {}
        ti_output[id]["rdf_zotero"] = {}
        expect(@book_recs[id]).not_to be_nil, "You must supply a MockMarcDocument to match for bib id:#{id}."
        ti_output[id]["ris"] = @book_recs[id].export_as_ris()
        ti_output[id]["endnote"] = @book_recs[id].export_as_endnote()
        ti_output[id]["endnote_xml"] = @book_recs[id].export_as_endnote_xml()
        ti_output[id]["rdf_zotero"] = @book_recs[id].export_as_rdf_zotero()
      end
      ti_data["1378974"] =
        { "ris" => { "author" => "AU  - Condie, Carol Joy", "year" => "PY  - 1954",
                    "publisher" => "PB  - Cornell Univ", "place" => "CY  - [Ithaca, N.Y.]" },
         "endnote" => { "author" => "%A Condie, Carol Joy", "year" => "%D  1954",
                        "publisher" => "%I Cornell Univ", "place" => "%C [Ithaca, N.Y.]" },
         "endnote_xml" => { "author" => "<author>Condie, Carol Joy", "year" => "<year>1954</year",
                            "publisher" => "<publisher>Cornell Univ", "place" => "<pub-location>[Ithaca, N.Y.]" },
         "rdf_zotero" => { "author" => "<foaf:surname>Condie</foaf:surname>", "year" => "<dc:date>1954</dc:date>",
                           "publisher" => "<foaf:name>Cornell Univ", "place" => "<vcard:locality>[Ithaca, N.Y.]" } }
      ti_data["5494906"] =
        { "ris" => { "author" => "AU  - Gauger, Wilhelm Peter Joachim", "year" => "PY  - 1965", "publisher" => "PB  - Freie Universität Berlin", "place" => "CY  - Berlin" },
          "endnote" => { "author" => "%A Gauger, Wilhelm Peter Joachim", "year" => "%D 1965", "publisher" => "%I Freie Universität Berlin", "place" => "%C Berlin" },
          "endnote_xml" => { "author" => "author>Gauger, Wilhelm Peter Joachim</author>", "year" => "<date>1965</date>", "publisher" => "<publisher>Ernst-Reuter-Gesellschaft</publisher>", "place" => "pub-location>Berlin</pub-location>" },
          "rdf_zotero" => { "author" => "<foaf:surname>Gauger</foaf:surname>", "year" => "<dc:date>1965</dc:date>", "publisher" => "<foaf:name>Freie Universität Berlin</foaf:name>", "place" => "<vcard:locality>Berlin</vcard:locality>" } }
      ti_data["3261564"] =
        { "ris" => { "author" => "AU  - Cakrabarttī, Utpalendu", "year" => "PY  - 1983", "publisher" => "PB  - INRECO", "place" => "CY  - Calcutta" },
          "endnote" => { "author" => "%A Cakrabarttī, Utpalendu", "year" => "%D 1983", "publisher" => "%I INRECO", "place" => "%C Calcutta" },
          "endnote_xml" => { "author" => "<author>Cakrabarttī, Utpalendu</author>", "year" => "<year>1983</year>", "publisher" => "<publisher>INRECO</publisher>", "place" => "<pub-location>Calcutta</pub-location>" },
          "rdf_zotero" => { "author" => "<foaf:surname>Cakrabarttī</foaf:surname>", "year" => "<dc:date>1983</dc:date>", "publisher" => "<foaf:name>INRECO</foaf:name>", "place" => "<vcard:locality>Calcutta</vcard:locality>" } }
      ti_data["6788245"] =
        { "ris" => { "author" => "AU  - Warner Bros. Pictures", "year" => "PY  - 2009", "publisher" => "PB  - Warner Home Video", "place" => "CY  - Burbank, CA" },
          "endnote" => { "author" => "%E Radcliffe, Daniel", "year" => "%D 2009", "publisher" => "%I Warner Home Video", "place" => "%C Burbank, CA" },
          "endnote_xml" => { "author" => "<author>Radcliffe, Daniel</author>", "year" => "<year>2009</year>", "publisher" => "<publisher>Warner Home Video</publisher>", "place" => "<pub-location>Burbank, CA</pub-location>" },
          "rdf_zotero" => { "author" => "<foaf:surname>Radcliffe</foaf:surname>", "year" => "<dc:date>2009</dc:date>", "publisher" => "<foaf:name>Warner Home Video</foaf:name>", "place" => "<vcard:locality>Burbank, CA</vcard:locality>" } }

      ti_data["9939352"] =
        { "ris" => { "author" => "AU  - Gray, Afsaneh", "year" => "PY  - 2017", "publisher" => "PB  - Oberon Books", "place" => "CY  - London" },
          "endnote" => { "author" => "%A Gray, Afsaneh", "year" => "%D 2017", "publisher" => "%I Oberon Books", "place" => "%C London" },
          "endnote_xml" => { "author" => "author>Gray, Afsaneh</author>", "year" => "<date>2017</date>", "publisher" => "publisher>Oberon Books</publisher>", "place" => "pub-location>London</pub-location>" },
          "rdf_zotero" => { "author" => "<foaf:surname>Gray</foaf:surname>", "year" => "<dc:date>2017</dc:date>", "publisher" => "<foaf:name>Oberon Books</foaf:name>", "place" => "<vcard:locality>London</vcard:locality>" } }
      ti_data["9496646"] =
        { "ris" => { "author" => "AU  - Bindal, Ahmet", "year" => "PY  - 2016", "publisher" => "PB  - Springer International Publishing", "place" => "CY  - Cham" },
          "endnote" => { "author" => "%A Bindal, Ahmet", "year" => "%D 2016", "publisher" => "%I Springer International Publishing", "place" => "%C Cham" },
          "endnote_xml" => { "author" => "<author>Bindal, Ahmet</author>", "year" => "<year>2016</year>", "publisher" => "<publisher>Springer International Publishing</publisher>", "place" => "<pub-location>Cham</pub-location>" },
          "rdf_zotero" => { "author" => "<foaf:surname>Bindal</foaf:surname>", "year" => "<dc:date>2016</dc:date>", "publisher" => "<foaf:name>Springer International Publishing</foaf:name>", "place" => "<vcard:locality>Cham</vcard:locality>" } }

      ti_ids.each do |id|
        ["ris", "endnote", "endnote_xml", "rdf_zotero"].each do |fmt|
          ["author", "year", "publisher", "place"].each do |fld|
            expect(ti_data[id]).not_to be_nil, "You must supply data to match for bib id:#{id}."
            expect(ti_data[id][fmt]).not_to be_nil, "You must supply format data to match for bib id:#{id} for format '#{fmt}'."
            expect(ti_data[id][fmt][fld]).not_to be_nil, "You must supply field text to match for bib id:#{id}, #{fld} in format '#{fmt}' properly."
            expect(ti_output[id][fmt]).to include(ti_data[id][fmt][fld]), "For bib id:#{id}, should output the #{fld} in format '#{fmt}' properly."
          end
        end
      end
    end
  end
end
