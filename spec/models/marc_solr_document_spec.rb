# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'bl_monkeys'
require 'stringio'

# NOTE: most of these functions and tests are copied directly from 
# # the blacklight-marc gem: blacklight-marc/spec/lib/marc_export_spec.rb

def marc_from_xml(string)    
  # NOTE: somewhere, one of the blacklight gems is changing the parser
  #   # used by XMLReader. Unless it's specified here ('rexml'), this function will
  #     # fail to produce any output
  #
  reader = MARC::XMLReader.new(StringIO.new(string),:parser => 'rexml')
  reader.each {|rec| return rec }
end


describe Blacklight::Solr::Document::MarcExport do

    class MockMarcDocument < SolrDocument
      include Blacklight::Solr::Document
      include Blacklight::Document::Extensions
      include Blacklight::Solr::Document::MarcExport
      include Blacklight::Solr::Document::Endnote
      include Blacklight::Solr::Document::RIS
      #extension_parameters[:marc_source_field] = :marc_display
      #extension_parameters[:marc_format_type] = :marcxml

      def setup_holdings_info(marc)
        ['']
      end

      attr_accessor :to_marc

      def initialize(marc_xml_str)
        @atts = []
        @atts[0] =  {:name => 'format', :value => ['Book']}
        self.to_marc = marc_from_xml(marc_xml_str)
      end

      def [](key) 
        if key.kind_of?(Integer)
          return @atts[key]
        else
          for i in 0...@atts.length
            return @atts[i][:value]if key == @atts[i][:name]
          end
        end
        return nil
      end

      def []=(key,value) 
          for i in 0...@atts.length
             if key == @atts[i][:name]
               @atts[i][:name] = key
               @atts[i][:value] = value 
               return @atts[i][:value]
             end
          end
        @atts <<  {:name =>key,:value => value} 
      end

    end
  
# the file xmldata from the support directory supplies marcxml data for testing.  
# in all of these definitions below.
  before(:all) do
    dclass = MockMarcDocument 
    dclass.use_extension( Blacklight::Solr::Document::Endnote )
    @book_rec8125253                     = dclass.new( rec8125253 )
    @book_rec8125253['url_access_display'] = "http://example.com"
    @book_record                     = dclass.new( book_record )
    @typical_record                     = dclass.new( standard_citation )
    @music_record                       = dclass.new( music_record )
    @dissertation_record                = dclass.new( dissertation_note_xml )
    @dissertation_record['format'] = ['Thesis'] 
    @record_without_245b                = dclass.new( record1_xml )
    @three_authors_record               = dclass.new( three_authors_xml )
    @record_without_authors             = dclass.new( record2_xml )
    @record_with_10plus_authors         = dclass.new( record3_xml )
    @year_range_record                  = dclass.new( year_range_xml )
    @no_date_record                     = dclass.new( no_date_xml )
    @section_title_record               = dclass.new( section_title_xml )
    @special_contributor_record         = dclass.new( special_contributor_with_author_xml )
    @record_without_citable_data        = dclass.new( no_good_data_xml )
    @record_with_bad_author             = dclass.new( bad_author_xml )
    @special_contributor_no_auth_record = dclass.new( special_contributor_no_author_xml )
    @record_utf8_decomposed             = dclass.new( utf8_decomposed_record_xml )

  end
  
  describe "export_as_cse_citation_txt" do
    it "should handle a typical record correctly" do
      expect(@typical_record.export_as_cse_citation_txt()[1]).to eq("Ferree DC, Warrington IJ, editors. Apples: botany, production, and uses. Oxon, U.K.: CABI Pub.; 2003.")
    end
  end

  describe "export_as_chicago_citation_txt" do
    it "should handle a typical record correctly" do
      expect(@typical_record.export_as_chicago_citation_txt()[1]).to eq("Ferree,  David C., and I. J. Warrington, eds. <i>Apples: Botany, Production, and Uses.</i> Oxon, U.K.: CABI Pub., 2003.")
    end
    it "should format a record w/o authors correctly" do
      expect(@record_without_authors.export_as_chicago_citation_txt()[1]).to eq("<i>Final Report to the Honorable John J. Gilligan, Governor.</i> [Columbus: Printed by the State of Ohio, Dept. of Urban Affairs, 1971.")
    end
    it "should format a citation without a 245b field correctly" do
      expect(@record_without_245b.export_as_chicago_citation_txt[1]).to eq("Janetzky,  Kurt, and Bernhard Brüchle. <i>The Horn.</i> London: Batsford, 1988.")
    end
    it "should format a citation with 4+ authors correctly" do
      chicago_text = @record_with_10plus_authors.export_as_chicago_citation_txt()[1]
      expect(chicago_text).to eq("Greer,  Lowell, Steven Lubin, Stephanie Chase, Johannes Brahms, Ludwig van Beethoven, Nikolaus von Krufft, John Doe, et al. <i>Music for Horn.</i> [United States]: Harmonia Mundi USA, 2001.")
      expect(chicago_text).to match(/John Doe, et al\./)
      expect(chicago_text).not_to match(/Jane Doe/)
    end
    it "should handle dissertation data correctly" do
      expect(@dissertation_record.export_as_chicago_citation_txt()[1]).to match('The Worm Has Turned')
    end
    it "should handle 3 authors correctly" do
      expect(@three_authors_record.export_as_chicago_citation_txt()[1]).to match(/^Doe,  John, Joe Schmoe, and Bill Schmoe\./)
    end
    it "should handle editors, translators, and compilers correctly" do
      pending("Need to pass various roles? to csl styles?")
      expect(@special_contributor_record.export_as_chicago_citation_txt()[1]).to eq("Doe, John <i>Title of Item.</i> Translated by Joe Schmoe. Edited by Bill Schmoe. Compiled by Susie Schmoe.  Publisher: Place, 2009.")
    end
    it "should handle editors, translators, and compilers correctly when there is no author present" do
      pending("Need to pass various roles? to csl styles?")
      expect(@special_contributor_no_auth_record.export_as_chicago_citation_txt()[1]).to eq("Schmoe, Joe trans., Bill Schmoe ed., and Susie Schmoe comp. <i>Title of Item.</i> Publisher: Place, 2009.")
    end
    it "should handle year ranges properly" do
      expect(@year_range_record.export_as_chicago_citation_txt()[1]).not_to match(/2000/)
    end
    it "should handle n.d. in the 260$c properly" do
      expect(@no_date_record.export_as_chicago_citation_txt()[1]).to match(/n\.d\.$/)
    end
    it "should handle section title appropriately" do
      pending("Need to pass section info to csl styles.")
      expect(@section_title_record.export_as_chicago_citation_txt()[1]).to eq("Schmoe, Joe <i>Main Title: Subtitle\.<\/i> Number of Part, <i>Name of Part\.<\/i> London: Batsford, 2001.")
    end
    it "should not fail if there is no citation data" do
      expect(@record_without_citable_data.export_as_chicago_citation_txt()[1]).to eq("")
    end
  end
  
  describe "export_as_apa_citation_txt" do
    it "should format a standard citation correctly" do
      expect(@typical_record.export_as_apa_citation_txt()[1]).to eq("Ferree, D. C., &amp; Warrington, I. J. (Eds.). (2003). <i>Apples: botany, production, and uses.</i> Oxon, U.K.: CABI Pub.")
    end
    
    it "should format a citation without a 245b field correctly" do
      expect(@record_without_245b.export_as_apa_citation_txt()[1]).to eq("Janetzky, K., &amp; Brüchle, B. (1988). <i>The horn.</i> London: Batsford.")
    end
    
    it "should format a citation without any authors correctly" do
      expect(@record_without_authors.export_as_apa_citation_txt()[1]).to eq("<i>Final report to the Honorable John J. Gilligan, Governor.</i> (1971). [Columbus: Printed by the State of Ohio, Dept. of Urban Affairs.")
    end
    
    it "should not fail if there is no citation data" do
      expect(@record_without_citable_data.export_as_apa_citation_txt()[1]).to eq("")
    end

    it "should not bomb with a null pointer if there if author data is empty" do
      expect(@record_with_bad_author.export_as_apa_citation_txt()[1]).to match(/.*Brüchle, B.*1988.*/)
    end
    
  end
  
  describe "export_as_mla_citation_txt" do
    it "should format a standard citation correctly" do
      expect(@typical_record.export_as_mla_citation_txt()[1]).to eq("Ferree,  David C., and I. J. Warrington, eds. <i>Apples: Botany, Production, and Uses.</i> Oxon, U.K.: CABI Pub., 2003. Print.")
    end

    it "should format an old time book correctly" do
      text = @book_rec8125253.export_as_mla_citation_txt()[1]
      match_str =  <<'CITE_MATCH'
Wake,  William. <i>Three Tracts against Popery. Written in the Year MDCLXXXVI. By William Wake, M.A. Student of Christ Church, Oxon; Chaplain to the Right Honourable the Lord Preston, and Preacher at S. Ann's Church, Westminster.</i> London: printed for Richard Chiswell, at the Rose and Crown in S. Paul's Church-Yard, 1687. Web.
CITE_MATCH
      puts text
      expect(text + "\n").to match(match_str)
    end
    
    it "should format a citation without a 245b field correctly" do
      expect(@record_without_245b.export_as_mla_citation_txt()[1]).to eq("Janetzky,  Kurt, and Bernhard Brüchle. <i>The Horn.</i> London: Batsford, 1988. Print.")
    end
    
    it "should format a citation without any authors correctly" do
      expect(@record_without_authors.export_as_mla_citation_txt()[1]).to eq("<i>Final Report to the Honorable John J. Gilligan, Governor.</i> [Columbus: Printed by the State of Ohio, Dept. of Urban Affairs, 1971. Print.")
    end
    
    it "should format a citation with 4+ authors correctly" do
      expect(@record_with_10plus_authors.export_as_mla_citation_txt()[1]).to eq("Greer,  Lowell et al. <i>Music for Horn.</i> [United States]: Harmonia Mundi USA, 2001. Print.")
    end
    
    it "should not fail if there is no citation data" do
      expect(@record_without_citable_data.export_as_mla_citation_txt()[1]).to eq(" Print.")      
    end
  end
  
  describe "export_as_openurl_ctx_kev" do
    it "should create the appropriate context object for books" do
      record = @typical_record.export_as_openurl_ctx_kev('Book')
      expect(record).to eq("ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.genre=book&amp;rft.btitle=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.title=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.au=&amp;rft.date=c2003.&amp;rft.place=Oxon%2C+U.K.+%3B&amp;rft.pub=CABI+Pub.%2C&amp;rft.edition=&amp;rft.isbn=")
      expect(record).not_to match(/.*rft.genre=article.*rft.issn=.*/)
    end
    it "should create the appropriate context object for journals" do
      record = @typical_record.export_as_openurl_ctx_kev('Journal')
      record_journal_other = @typical_record.export_as_openurl_ctx_kev('Journal/Magazine')
      expect(record).to eq("ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&amp;rfr_id=info%3Asid%2Fblacklight.rubyforge.org%3Agenerator&amp;rft.genre=article&amp;rft.title=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.atitle=Apples+%3A+botany%2C+production%2C+and+uses+%2F&amp;rft.date=c2003.&amp;rft.issn=")
      expect(record_journal_other).to eq(record) and
      expect(record).not_to match(/.*rft.genre=book.*rft.isbn=.*/)
    end
    it "should create the appropriate context object for other content" do
      record = @typical_record.export_as_openurl_ctx_kev('NotARealFormat')
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

  describe "export_as_refworks_marc_txt" do
    it "should export correctly" do
      expect(@music_record.export_as_refworks_marc_txt).to eq("LEADER 01828cjm a2200409 a 4500001    a4768316\n003    SIRSI\n007    sd fungnnmmned\n008    020117p20011990xxuzz    h              d\n245 00 Music for horn |h[sound recording] / |cBrahms, Beethoven, von Krufft.\n260    [United States] : |bHarmonia Mundi USA, |cp2001.\n700 1  Greer, Lowell.\n700 1  Lubin, Steven.\n700 1  Chase, Stephanie, |d1957-\n700 12 Brahms, Johannes, |d1833-1897. |tTrios, |mpiano, violin, horn, |nop. 40, |rE? major.\n700 12 Beethoven, Ludwig van, |d1770-1827. |tSonatas, |mhorn, piano, |nop. 17, |rF major.\n700 12 Krufft, Nikolaus von, |d1779-1818. |tSonata, |mhorn, piano, |rF major.\n")
    end
    describe "for UTF-8 record" do
      it "should export in Unicode normalized C form" do        
        @utf8_exported = @record_utf8_decomposed.export_as_refworks_marc_txt

        if defined? Unicode
          expect(@utf8_exported).not_to include("\314\204\312\273") # decomposed
          expect(@utf8_exported).to include("\304\253\312\273") # C-form normalized
        end
      end
    end
  end

  describe "Export as RIS  means that it " do
    it "should export a simple record correctly" do
      ris_file = @music_record.export_as_ris
      ris_entries = Hash.new {|hash, key| hash[key] = Set.new }
      ris_file.each_line do |line|
        line =~ /^(..?)  - (.*)$/
        ris_entries[$1] << $2
      end
      expect(ris_entries["TY"]).to eq(Set.new(["BOOK"])) 
      expect(ris_entries["TI"]).to eq(Set.new(["Music for horn"])) 
      expect(ris_entries["PY"]).to eq(Set.new(["2001"])) 
      expect(ris_entries["PB"]).to eq(Set.new([" Harmonia Mundi USA"])) 
      expect(ris_entries["CY"]).to eq(Set.new(["[United States]"])) 
      expect(ris_entries["M2"]).to eq(Set.new(["http://newcatalog.library.cornell.edu/catalog/"])) 
      expect(ris_entries["N1"]).to eq(Set.new(["http://newcatalog.library.cornell.edu/catalog/"])) 
      expect(ris_entries["ER"]).to eq(Set.new([""])) 
    end
#CY  - Washington, D.C.
#M2  - http://newcatalog.library.cornell.edu/catalog/
#N1  - http://newcatalog.library.cornell.edu/catalog/
#KW  - Anthropologists' writings, American. 
#KW  - Anthropology Poetry. 
#KW  - American poetry 20th century. 
#KW  - Anthropologists' writings, English. 
#KW  - English poetry 20th century. 
#SN  - 091316710X : 
#ER  - 
    it "should export a typical book record correctly" do
      ris_file = @book_record.export_as_ris
      ris_entries = Hash.new {|hash, key| hash[key] = Set.new }
      ris_file.each_line do |line|
        print line
        line =~ /^(..?)  - (.*)$/
        ris_entries[$1] << $2
      end
      expect(ris_entries["TY"]).to eq(Set.new(["BOOK"])) 
      expect(ris_entries["TI"]).to eq(Set.new(["Reflections: the anthropological muse"])) 
      expect(ris_entries["PY"]).to eq(Set.new(["1985"])) 
      expect(ris_entries["PB"]).to eq(Set.new([" American Anthropological Association"])) 
      expect(ris_entries["CY"]).to eq(Set.new(["Washington, D.C."])) 
      expect(ris_entries["ER"]).to eq(Set.new([""])) 
    end
  end
  describe "Export as endnote means that it " do
    it "should export_endnote_correctly" do
      endnote_file = @music_record.export_as_endnote
      # We have to parse it a bit to check it.
      endnote_entries = Hash.new {|hash, key| hash[key] = Set.new }
      endnote_file.each_line do |line|
        line =~ /\%(..?) (.*)$/
        endnote_entries[$1] << $2
      end

      expect(endnote_entries["0"]).to eq(Set.new(["Book"])) # I have no idea WHY this is correct, it is definitely not legal, but taking from earlier test for render_endnote in applicationhelper, the previous version of this.  jrochkind.
      #expect(endnote_entries["D"]).to eq(Set.new(["p2001. "]))
      expect(endnote_entries["D"]).to eq(Set.new(["2001"]))
      expect(endnote_entries["C"]).to eq(Set.new(["[United States]"]))
      expect(endnote_entries["E"]).to eq(Set.new(["Greer, Lowell ", "Lubin, Steven ", "Chase, Stephanie ", "Brahms, Johannes ", "Beethoven, Ludwig van ", "Krufft, Nikolaus von "]))
      expect(endnote_entries["I"]).to eq(Set.new(["Harmonia Mundi USA"]))
      expect(endnote_entries["T"]).to eq(Set.new(["Music for horn "]))

      #nothing extra
      #expect(Set.new(endnote_entries.keys)).to eq(Set.new(["0", "C", "D", "E", "I", "T"]))      
      expect(Set.new(endnote_entries.keys)).to eq(Set.new(["0", "E", "T", "I", "C", "D", "Z", nil]))      
    end
  end

  describe "CSL title transformation" do

    class MockMarcDocument < SolrDocument
      include Blacklight::Solr::Document
      include Blacklight::Document::Extensions
      include Blacklight::Solr::Document::MarcExport
    end

    before(:each) do 
      dclass = MockMarcDocument 
      dclass.use_extension( Blacklight::Solr::Document::Endnote )
      @typical_record                     = dclass.new( standard_citation )
    end

    it "should transform a normal APA title properly" do
      expect(@typical_record.export_as_apa_citation_txt[1]).to match("<i>Apples: botany, production, and uses.</i>")
    end
    it "should transform a normal MLA title properly" do
      expect(@typical_record.export_as_mla_citation_txt[1]).to match("<i>Apples: Botany, Production, and Uses.</i>")
    end

  end

end
