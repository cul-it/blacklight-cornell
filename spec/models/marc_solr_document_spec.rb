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
      include Blacklight::Solr::Document::Endnote_xml
      include Blacklight::Solr::Document::Zotero
      #extension_parameters[:marc_source_field] = :marc_display
      #extension_parameters[:marc_format_type] = :marcxml

      def xsetup_holdings_info(marc)
        ['']
      end
      def ysetup_holdings_info(record)
        if  self["holdings_record_display"].blank?
          return ['']
        end
        holdings_arr = self["holdings_record_display"]
        holdings = []
        where_arr = holdings_arr.collect { | h |  JSON.parse(h).with_indifferent_access }
        where = where_arr.collect do | h |  
           "#{h['locations'][0]['library']}  #{h['callnos'][0]}" unless h.blank? or h['locations'].blank? or h['callnos'].blank?
         end
         where
       end
       def setup_holdings_info(record)
         where = ['']
        if (self["holdings_json"].present?)
          holdings_json = JSON.parse(self["holdings_json"])
          holdings_keys = holdings_json.keys
          where = holdings_keys.collect do
            | k |
            l = holdings_json[k]
            "#{l['location']['library']}  #{l['call']}" unless l.blank? or l['location'].blank? or l['call'].blank?
           end
        end
        where
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
  
# the file xmldata, and the various <bibid>.rb files,from the support directory supplies marcxml data for testing.  
# in all of these definitions below.
  before(:all) do
    @book_recs = {} 
    # descriptive strings from the csl files.
    @apa_match_style = "American Psychological Association 6th edition"
    @cse_match_style = "The Council of Science Editors style 8th edition, Citation-Sequence system: numbers in text, sorted by order of appearance in text."
    @chicago_match_style = "Chicago format with full notes and bibliography"
    @mla_match_style = "This style adheres to the MLA 7th edition handbook and contains modifications to these types of sources: e-mail, forum posts, interviews, manuscripts, maps, presentations, TV broadcasts, and web pages."
    @mla8_match_style = "This style adheres to the MLA 8th edition handbook. Follows the structure of references as outlined in the MLA Manual closely"
    dclass = MockMarcDocument 
    dclass.use_extension( Blacklight::Solr::Document::Endnote )
    ids = ["1001", "1002", "393971", "1378974", "1676023", "2083900", "3261564", "3902220",
            "5494906", "5558811", "6146988", "6788245", "7292123", "7981095", "8069112", "8125253",
            "8392067", "8696757", "8867518", "8632993","9305118", "9448862", "9496646", "9939352", "10055679",]
    # Turn all the xml data into MockMarcDocuments records.
    ids.each { |id| 
      @book_recs[id]                      = dclass.new( send("rec#{id}"))
      @book_recs[id]['id'] = id
      # just a stub valid only for bibid 10055679#
      @book_recs[id]['holdings_json']  = "{\"10368366\":{\"location\":{\"code\":\"mann\",\"number\":69,\"name\":\"Mann Library\",\"library\":\"Mann Library\",\"hoursCode\":\"mann\"},\"call\":\"SF98.A5 M35 2017\",\"circ\":true,\"date\":1506532638,\"items\":{\"count\":1,\"unavail\":[{\"id\":10369482,\"status\":{\"code\":{\"3\":\"Renewed\"},\"due\":1541286000,\"date\":1509719141}}]}}}"
    }
    # Fix up some parameters supplied by SOLR
    #electronic
    eids = ["8125253","8696757","8867518","5558811"]                     
    # add on url information.
    # more than url is required.
    eids.each { |id| 
      @book_recs[id]['url_access_display'] = ["http://example.com"]
      @book_recs[id]["online"]= ["Online"]
    }
    #music
    mids = ["3261564"]                     
    mids.each { |id| 
      @book_recs[id]['format'] = ["Musical Recording"]
    } 
    #video
    @book_recs["6788245"]["format"] = ["Video"] 
    #thesis
    @book_recs["5494906"]["format"] = ["Thesis"] 
    @book_recs["1378974"]["format"] = ["Thesis"] 
    #map
    @book_recs["1676023"]["format"] =['Map or Globe'] 
    @book_record                     = dclass.new( book_record )
    @typical_record                     = dclass.new( standard_citation )
    @music_record                       = dclass.new( music_record )
    @music_record['format'] = ['Musical Recording'] 
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
      expect(chicago_text).to eq("Greer,  Lowell, Steven Lubin, Stephanie Chase, Stephanie Chaste, Stephanie Waste, Stephanie Paste, John Doe, et al. <i>Music for Horn.</i> [United States]: Harmonia Mundi USA, 2001.")
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
    it "should format a standard MLA citation correctly" do
      expect(@typical_record.export_as_mla_citation_txt()[1]).to eq("Ferree,  David C., and I. J. Warrington, eds. <i>Apples: Botany, Production, and Uses.</i> Oxon, U.K.: CABI Pub., 2003. Print.")
    end

# Must not interpret analytic additional personal names as applying to citation. 
# DISCOVERYACCESS-4195
    it "should format an analytic entry correctly for mla (7)" do
      id = "8632993"
      cite_info = @book_recs[id].export_as_mla_citation_txt()
      cite_style = cite_info[0]
      cite_text = cite_info[1]
      match_style = @mla_match_style 
      # because of the here doc syntax, the variable always ends in newline.
      # so, must account for that when we handle the expect.
      match_str =  <<'CITE_MATCH'
Formichi,  Chiara, ed. <i>Religious Pluralism, State and Society in Asia.</i> London: Routledge, 2014. Print.
CITE_MATCH
      expect(cite_text + "\n").to match(match_str)
      expect(cite_style).to match(match_style)
    end 
# DISCOVERYACCESS-1677
# roman numerals need to be properly eliminated from the date field.
# DISCOVERYACCESS-1677
    it "should format an old time book correctly for mla (7)" do
      id = "8125253"
      cite_info = @book_recs[id].export_as_mla_citation_txt()
      cite_style = cite_info[0]
      cite_text = cite_info[1]
      match_style = @mla_match_style 
      # because of the here doc syntax, the variable always ends in newline.
      # so, must account for that when we handle the expect.
      match_str =  <<'CITE_MATCH'
Wake,  William. <i>Three Tracts against Popery. Written in the Year MDCLXXXVI. By William Wake, M.A. Student of Christ Church, Oxon; Chaplain to the Right Honourable the Lord Preston, and Preacher at S. Ann's Church, Westminster.</i> London: printed for Richard Chiswell, at the Rose and Crown in S. Paul's Church-Yard, 1687. Web.
CITE_MATCH
      expect(cite_text + "\n").to eq(match_str)
      expect(cite_style).to eq(match_style)
    end
 #Chicago 17th ed. format.
 # Official documentation: http://www.chicagomanualofstyle.org/16/ch14/ch14_sec018.html
 #DISCOVERYACCESS-1677
    it "should format an ebook correctly for chicago" do
      id = "8696757"
      cite_info = @book_recs[id].export_as_chicago_citation_txt()
      cite_style = cite_info[0]
      cite_text = cite_info[1]
      match_style = @chicago_match_style 
      match_str =  <<'CITE_MATCH'
Funk,  Tom. <i>Advanced Social Media Marketing: How to Lead, Launch, and Manage a Successful Social Media Program.</i> Berkeley, CA: Apress, 2013. https://doi.org/10.1007/978-1-4302-4408-0.
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline.
      # so, must account for that when we handle the expect.
      expect(cite_text + "\n").to eq(match_str)
      expect(cite_style).to eq(match_style)
    end

#      DISCOVERYACCESS-1677
# Official documentation: http://www.chicagomanualofstyle.org/16/ch14/ch14_sec018.html
#For a book with two authors, note that only the 
#first-listed name is inverted in the bibliography entry.
    it "should format an 2 author book  correctly for chicago" do
      id = "6146988"
      cite_info = @book_recs[id].export_as_chicago_citation_txt()
      cite_style = cite_info[0]
      cite_text = cite_info[1]
      match_style = @chicago_match_style 
      match_str =  <<'CITE_MATCH'
Ward,  Geoffrey C, and Ken Burns. <i>The War: an Intimate History, 1941-1945.</i> New York: A.A. Knopf, 2007.
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline.
      # so, must account for that when we handle the expect.
      expect(cite_text + "\n").to eq(match_str)
      expect(cite_style).to eq(match_style)
    end

    it "should format an corporate author book  correctly for chicago" do
      id = "393971"
      cite_info = @book_recs[id].export_as_chicago_citation_txt()
      cite_style = cite_info[0]
      cite_text = cite_info[1]
      match_style = @chicago_match_style 
      match_str =  <<'CITE_MATCH'
Memorial University of Newfoundland. <i>Geology Report.</i> St. John's, n.d.
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline.
      # so, must account for that when we handle the expect.
      expect(cite_text + "\n").to eq(match_str)
      expect(cite_style).to       eq(match_style)
    end

 #@DISCOVERYACCESS-3175
    it "should format an an edited book book correctly for chicago" do
      id = "9448862"
      cite_info = @book_recs[id].export_as_chicago_citation_txt()
      cite_style = cite_info[0]
      cite_text = cite_info[1]
      match_style = @chicago_match_style 
      match_str =  <<'CITE_MATCH'
Modemuseum Provincie Antwerpen. <i>Fashion Game Changers: Reinventing the 20th-Century Silhouette.</i> Edited by Karen van Godtsenhoven, Miren Arzalluz, and Kaat Debo. London: Bloomsbury Visual Arts, an imprint of Bloomsbury Publishing PLC, 2016.
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline.
      # so, must account for that when we handle the expect.
      expect(cite_text + "\n").to eq(match_str)
      expect(cite_style).to eq(match_style)
    end

 # DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
 #  16 #Shannon, Timothy J. The Seven Years' War In North America : a Brief History with Documents. Boston: Bedford/St    . Martin's, 2014.'
 # has a 264 with indicator 1, and another with indicator 4.
    it "should format use citation date information properly for MLA" do
      id = "8392067"
      cite_info = @book_recs[id].export_as_mla_citation_txt()
      cite_style = cite_info[0]
      cite_text = cite_info[1]
      match_style = @mla_match_style 
      match_str =  <<'CITE_MATCH'
Shannon,  Timothy J. <i>The Seven Years' War in North America: a Brief History with Documents.</i> Boston: Bedford/St. Martin's, 2014. Print.
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline, but the returned string does not.
      # so, must account for that when we handle the expect.
      expect(cite_text + "\n").to match(match_str)
      expect(cite_style).to match(match_style)
    end

    it "should format use citation date information properly for MLA" do
      id = "8867518"
      cite_info = @book_recs[id].export_as_mla_citation_txt()
      match_style = @mla_match_style 
      match_str =  <<'CITE_MATCH'
Fitch,  G. Michael. <i>The Impact of Hand-Held and Hands-Free Cell Phone Use on Driving Performance and Safety-Critical Event Risk: Final Report.</i> [Washington, DC]: U.S. Department of Transportation, National Highway Traffic Safety Administration, 2013. Web.
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline, but the returned string does not.
      # so, must account for that when we handle the expect.
      expect(cite_info[1] + "\n").to match(match_str)
      expect(cite_info[0]).to match(match_style)
    end
#User needs to cite a record by a corporate author in MLA style # NRC  / corp author. make sure (U.S.) is gone.
#    Then I should see the label 'MLA 7th ed. National Research Council. Beyond Six Billion: Forecasting the World's Population. Washington, D.C    .: National Academy Press, 2000.'
    it "should format use corporate author information properly for MLA" do
      id = "3902220"
      cite_info = @book_recs[id].export_as_mla_citation_txt()
      match_style = @mla_match_style 
      match_str =  <<'CITE_MATCH'
National Research Council. <i>Beyond Six Billion: Forecasting the World's Population.</i> Washington, D.C.: National Academy Press, 2000. Print.
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline, but the returned string does not.
      # so, must account for that when we handle the expect.
      expect(cite_info[1] + "\n").to match(match_str)
      expect(cite_info[0]).to match(match_style)
    end
###
#
    it "should format mla7,8, and cse citation information properly for ebook" do
      id = "5558811"
      cite_info={}
      match_str={}
      match_style={}
      match_style['mla7'] = @mla_match_style
      match_style['mla8'] = @mla8_match_style
      match_style['cse'] = @cse_match_style
      match_style['chicago'] = @chicago_match_style
      match_style['apa'] = @apa_match_style
      @book_recs[id]['url_access_display'] = ["http://opac.newsbank.com/select/evans/385"]
      ["mla","mla8","cse","chicago","apa"].each   do |fmt| 
        cite_info[fmt] = @book_recs[id].send("export_as_#{fmt}_citation_txt")
      end
      # Account irregular name for mla7 citation -- ..as_mla_...
      cite_info['mla7'] = cite_info['mla']
      match_str['mla7'] =  <<'CITE_MATCH'
Eliot,  John, John Cotton, and Robert Boyle. <i>Mamusse Wunneetupanatamwe Up-Biblum God Naneeswe Nukkone Testament Kah Wonk Wusku Testament.</i> Cambridge [Mass.].: Printeuoop nashpe Samuel Green., 1685. Web.
CITE_MATCH
      match_str['mla8'] =  <<'CITE_MATCH'
Eliot, John, et al. <i>Mamusse Wunneetupanatamwe Up-Biblum God Naneeswe Nukkone Testament Kah Wonk Wusku Testament.</i> Printeuoop nashpe Samuel Green., 1685, http://opac.newsbank.com/select/evans/385.
CITE_MATCH
      match_str['cse'] =  <<'CITE_MATCH'
Eliot J, Cotton J, Boyle R. Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament. Cambridge [Mass.].: Printeuoop nashpe Samuel Green.; 1685.
CITE_MATCH
      match_str['chicago'] =  <<'CITE_MATCH'
Eliot,  John, John Cotton, and Robert Boyle. <i>Mamusse Wunneetupanatamwe Up-Biblum God Naneeswe Nukkone Testament Kah Wonk Wusku Testament.</i> Cambridge [Mass.].: Printeuoop nashpe Samuel Green., 1685. http://opac.newsbank.com/select/evans/385.
CITE_MATCH
      match_str['apa'] =  <<'CITE_MATCH'
Eliot, J., Cotton, J., &amp; Boyle, R. (1685). <i>Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament.</i> Cambridge [Mass.].: Printeuoop nashpe Samuel Green. Retrieved from http://opac.newsbank.com/select/evans/385
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline, but the returned string does not.
      # so, must account for that when we handle the expect.
        ["mla7","mla8","cse","chicago","apa"].each   do |fmt| 
      expect(cite_info[fmt][1] + "\n").to match(match_str[fmt]), "Bibid #{id} #{fmt} citation text does not match. Created string '#{cite_info[fmt][1]}'  does not match required text: '#{match_str[fmt]}' "
      expect(cite_info[fmt][0]).to match(match_style[fmt]), "Bibid #{id} #{fmt} style description does not match. Created string '#{cite_info[fmt][0]}'  does not match required text: '#{match_style[fmt]}' "
      end
    end

    it "should format mla7,8, and cse citation information properly" do
      id = "7292123"
      mla7_cite_info = @book_recs[id].export_as_mla_citation_txt()
      mla8_cite_info = @book_recs[id].export_as_mla8_citation_txt()
      cse_cite_info = @book_recs[id].export_as_cse_citation_txt()
      mla7_match_str =  <<'CITE_MATCH'
Jacobs,  Alan. <i>The Pleasures of Reading in an Age of Distraction.</i> New York: Oxford University Press, 2011. Print.
CITE_MATCH
      mla8_match_str =  <<'CITE_MATCH'
Jacobs, Alan. <i>The Pleasures of Reading in an Age of Distraction.</i> Oxford University Press, 2011.
CITE_MATCH
      cse_match_str =  <<'CITE_MATCH'
Jacobs A. The pleasures of reading in an age of distraction. New York: Oxford University Press; 2011.
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline, but the returned string does not.
      # so, must account for that when we handle the expect.
      expect(mla7_cite_info[1] + "\n").to match(mla7_match_str)
      expect(mla7_cite_info[0]).to match(@mla_match_style)
      expect(mla8_cite_info[1] + "\n").to match(mla8_match_str)
      expect(mla8_cite_info[0]).to match(@mla8_match_style)
      expect(cse_cite_info[1] + "\n").to match(cse_match_str)
      expect(cse_cite_info[0]).to match(@cse_match_style)
    end
# APA 6th ed.
# Not sure if this is official documentation:
# http://www.muhlenberg.edu/library/reshelp/apa_example.pdf
# Publication Manual of the American Psychological Association, 6th ed. Washington, DC:
# American Psychological Association, 2010.
# Uris Library Reference (Non-Circulating) BF76.7 .P83 2010
# examples:
# Shotton, M. A. (1989) Computer addition? A study of computer dependency. London, England: Taylor & Francis
# Gregory, G., & Parry, T. (2006). Designing brain-compatible learning (3rd ed.). Thousand Oaks, CA: Corwin. 
# 24 # DISCOVERYACCESS-1677 -Publication info isn't in citation even if it exists- 
#
    it "should format APA citation information properly" do
      id = "8069112"
      apa_cite_info = @book_recs[id].export_as_apa_citation_txt()
      apa_match_str =  <<'CITE_MATCH'
Cohen, A. I. (2013). <i>Social media: legal risk and corporate policy.</i> New York: Wolters Kluwer Law &amp; Business.
CITE_MATCH
      expect(apa_cite_info[1] + "\n").to match(apa_match_str)
      expect(apa_cite_info[0]).to match(@apa_match_style)
    end

#@DISCOVERYACCESS-1677
    it "should format APA citation information properly for multiple authors" do
      id = "6146988"
      apa_cite_info = @book_recs[id].export_as_apa_citation_txt()
      apa_match_str =  <<'CITE_MATCH'
Ward, G. C., &amp; Burns, K. (2007). <i>The war: an intimate history, 1941-1945.</i> New York: A.A. Knopf.
CITE_MATCH
      expect(apa_cite_info[1] + "\n").to match(apa_match_str)
      expect(apa_cite_info[0]).to match(@apa_match_style)
end

    it "should format APA citation information properly for corporate author" do
      id = "393971"
      apa_cite_info = @book_recs[id].export_as_apa_citation_txt()
      apa_match_str =  <<'CITE_MATCH'
Memorial University of Newfoundland. <i>Geology report.</i> St. John's.
CITE_MATCH
      expect(apa_cite_info[1] + "\n").to match(apa_match_str)
      expect(apa_cite_info[0]).to match(@apa_match_style)
end

 # DISCOVERYACCESS-2816 - Manuscript records should use cite as field
 # Because of citeas, all fields should be the same.
    it "should format manuscript citation information properly" do
      id = "2083900"
      @book_recs[id]['format'] = ['Manuscript/Archive'] 
      mla7_cite_info = @book_recs[id].export_as_mla_citation_txt()
      mla8_cite_info = @book_recs[id].export_as_mla8_citation_txt()
      cse_cite_info = @book_recs[id].export_as_cse_citation_txt()
      apa_cite_info = @book_recs[id].export_as_apa_citation_txt()
      #because of the citeas field, these should all be the same.
      manu_match_str =  <<'CITE_MATCH'
<i>Ezra Cornell Papers, #1-1-1.  Division of Rare and Manuscript Collections, Cornell University Library.</i>
CITE_MATCH
      cse_match_str =  <<'CITE_MATCH'
 Ezra Cornell papers, #1-1-1.  Division of Rare and Manuscript Collections, Cornell University Library.
CITE_MATCH
      apa_match_str =  <<'CITE_MATCH'
<i>Ezra Cornell papers, #1-1-1.  Division of Rare and Manuscript Collections, Cornell University Library.</i>
CITE_MATCH
      # because of the here doc syntax, the variable always ends in newline, but the returned string does not.
      # so, must account for that when we handle the expect.
      expect(mla7_cite_info[1] + "\n").to match(manu_match_str)
      expect(mla7_cite_info[0]).to match(@mla_match_style)
      expect(mla8_cite_info[1] + "\n").to match(manu_match_str)
      expect(mla8_cite_info[0]).to match(@mla8_match_style)
      expect(cse_cite_info[1] + "\n").to match(cse_match_str)
      expect(cse_cite_info[0]).to match(@cse_match_style)
      expect(apa_cite_info[1] + "\n").to match(apa_match_str)
      expect(apa_cite_info[0]).to match(@apa_match_style)
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
      expect(@music_record.export_as_refworks_marc_txt).to match("LEADER 01828cjm a2200409 a 4500001    a4768316\n003    SIRSI\n007    sd fungnnmmned\n008    020117p20011990xxuzz    h              d\n245 00 Music for horn |h[sound recording] / |cBrahms, Beethoven, von Krufft.\n260    [United States] : |bHarmonia Mundi USA, |cp2001.\n700 1  Greer, Lowell.\n700 1  Lubin, Steven.\n700 1  Chase, Stephanie, |d1957-\n700 12 Brahms, Johannes, |d1833-1897. |tTrios, |mpiano, violin, horn, |nop. 40, |rE? major.\n700 12 Beethoven, Ludwig van, |d1770-1827. |tSonatas, |mhorn, piano, |nop. 17, |rF major.\n700 12 Krufft, Nikolaus von, |d1779-1818. |tSonata, |mhorn, piano, |rF major.\n")
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
      expect(ris_entries["TY"]).to eq(Set.new(["SOUND"])) 
      expect(ris_entries["TI"]).to eq(Set.new(["Music for horn"])) 
      expect(ris_entries["PY"]).to eq(Set.new(["2001"])) 
      expect(ris_entries["PB"]).to eq(Set.new([" Harmonia Mundi USA"])) 
      expect(ris_entries["CY"]).to eq(Set.new(["[United States]"])) 
      expect(ris_entries["M2"]).to eq(Set.new(["http://newcatalog.library.cornell.edu/catalog/"])) 
      expect(ris_entries["N1"]).to eq(Set.new(["http://newcatalog.library.cornell.edu/catalog/"])) 
      expect(ris_entries["ER"]).to eq(Set.new([""])) 
    end
#SN  - 091316710X : 
    it "should export a typical book record correctly" do
      id = "1001"
      @book_recs[id]['holdings_json']  = "{\"5195\":{\"location\":{\"code\":\"olin,anx\",\"number\":101,\"name\":\"Library Annex\",\"library\":\"Library Annex\",\"hoursCode\":\"annex\"},\"call\":\"PS591.A58 R33\",\"circ\":true,\"date\":959745600,\"items\":{\"count\":1,\"avail\":1}}}" 
      ris_file = @book_recs[id].export_as_ris
      ris_entries = Hash.new {|hash, key| hash[key] = Set.new }
      ris_file.each_line do |line|
        line =~ /^(..?)  - (.*)$/
        ris_entries[$1] << $2
      end
      expect(ris_entries["TY"]).to eq(Set.new(["BOOK"])) 
      expect(ris_entries["TI"]).to eq(Set.new(["Reflections: the anthropological muse"])) 
      expect(ris_entries["M2"]).to eq(Set.new(["http://newcatalog.library.cornell.edu/catalog/1001"])) 
      expect(ris_entries["PY"]).to eq(Set.new(["1985"])) 
      expect(ris_entries["KW"]).to eq(Set.new(["Anthropologists' writings, American. ", "Anthropology Poetry. ", "American poetry 20th century. ", "Anthropologists' writings, English. ", "English poetry 20th century. "]))
      expect(ris_entries["PB"]).to eq(Set.new([" American Anthropological Association"])) 
      expect(ris_entries["CY"]).to eq(Set.new(["Washington, D.C."])) 
      expect(ris_entries["SN"]).to eq(Set.new(["091316710X  "])) 
      expect(ris_entries["CN"]).to eq(Set.new(["Library Annex  PS591.A58 R33"])) 
      expect(ris_entries["ER"]).to eq(Set.new([""])) 
    end

    it "should export a typical ebook record correctly" do
      id = "5558811"
      @book_recs[id]["online"]= ["Online"]
      @book_recs[id]['url_access_display'] = ["http://opac.newsbank.com/select/evans/385"]
      @book_recs[id]['language_facet'] = ["Algonquian (Other)"] 
      ris_file = @book_recs[id].export_as_ris
      ris_entries = Hash.new {|hash, key| hash[key] = Set.new }
      ris_file.each_line do |line|
        line =~ /^(..?)  - (.*)$/
        ris_entries[$1] << $2
      end
      expect(ris_entries["TY"]).to eq(Set.new(["EBOOK"])) 
      expect(ris_entries["AU"]).to eq(Set.new(["Company for Propagation of the Gospel in New England and the Parts Adjacent in America"])) 
      expect(ris_entries["TI"]).to eq(Set.new(["Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament"])) 
      expect(ris_entries["PY"]).to eq(Set.new(["1685"])) 
      expect(ris_entries["PB"]).to eq(Set.new([" Printeuoop nashpe Samuel Green."])) 
      expect(ris_entries["LA"]).to eq(Set.new(["Algonquian (Other)"])) 
      expect(ris_entries["CY"]).to eq(Set.new(["Cambridge [Mass.]."])) 
      expect(ris_entries["UR"]).to eq(Set.new(["http://opac.newsbank.com/select/evans/385"]))
      expect(ris_entries["M2"]).to eq(Set.new(["http://newcatalog.library.cornell.edu/catalog/#{id}"])) 
      expect(ris_entries["ER"]).to eq(Set.new([""])) 
    end
  end
#

  describe "Export as endnote means that it " do
    it "should export endnote properly"  do
      endnote_file = @music_record.export_as_endnote
      # We have to parse it a bit to check it.
      endnote_entries = Hash.new {|hash, key| hash[key] = Set.new }
      endnote_file.each_line do |line|
        line =~ /\%(..?) (.*)$/
        endnote_entries[$1] << $2
      end

      expect(endnote_entries["0"]).to eq(Set.new(["Music"])) # I have no idea WHY this is correct, it is definitely not legal, but taking from earlier test for render_endnote in applicationhelper, the previous version of this.  jrochkind.
      #expect(endnote_entries["D"]).to eq(Set.new(["p2001. "]))
      expect(endnote_entries["D"]).to eq(Set.new(["2001"]))
      expect(endnote_entries["C"]).to eq(Set.new(["[United States]"]))
      expect(endnote_entries["E"]).to eq(Set.new(["Greer, Lowell ", "Lubin, Steven ", "Chase, Stephanie ","Chase, Stepehn ","Chaste, Stepehn ","Brahms, Johannes ", "Beethoven, Ludwig van ", "Krufft, Nikolaus von "]))
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


  describe "Format exports" do
    it "should export the title and type in multiple formats correctly" do
      ti_ids = ["1001", "1676023", "3261564", "5494906", "5558811", "6788245"]
      ti_data = {} 
      ti_output = {} 
      ti_data["1001"] = 
                {"endnote" => {"title" => "%T Reflections  the anthropological muse","type" => "%0 Book"},
                "ris" => {"title" => "TI  - Reflections: the anthropological muse", "type" => "TY  - BOOK"},
                "endnote_xml"=>{"title"=>"<title>Reflections: the anthropological muse</title>", "type" => "<ref-type name=\"Book\">6</ref-type>"},
                "rdf_zotero"=>{"title"=>"<dc:title>Reflections: the anthropological muse</dc:title>", "type" => "<z:itemType>book</z:itemType>"}}
      # Sound, music 
      ti_data["3261564"] = 
               {"ris" => { "title"=> 'TI  - Debabrata Biśvāsa'  , "type" => 'TY  - SOUND' },
                "endnote"  => {"title"=> '%T Debabrata Biśvāsa'  , "type" => '%0 Music' },
                "endnote_xml"  => {"title"=> '<title>Debabrata Biśvāsa</title>'  , "type" =>'<ref-type name="Music">61</ref-type>'  },
                "rdf_zotero" =>  {"title"=>'<dc:title>Debabrata Biśvāsa</dc:title>'  , "type" => '<z:itemType>audioRecording</z:itemType>' }}
      #EBOOK 
      ti_data["5558811"] = 
               { "ris" =>    {"title" => 'TI  - Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament',"type" =>'TY  - EBOOK'},
                 "endnote" => {"title" => '%T Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament', "type" =>  '%0 Electronic Book'},
                 "endnote_xml" => {"title" => '<title>Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament</title>', "type" => "<ref-type name=\"Book\">6</ref-type>"},
                 "rdf_zotero" => { "title" =>  '<dc:title>Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament</dc:title>', "type" =>  '<z:itemType>book</z:itemType>'}
}
      #Thesis
      ti_data["5494906"] = 
          { "ris" =>           {"title" => 'TI  - Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700',"type" =>'TY  - THES'},
            "endnote" =>       {"title" => '%T Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700', "type" =>  '%0 Thesis'},
            "endnote_xml" =>   {"title" => '<title>Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700</title>', "type" => "<ref-type name=\"Thesis\">32</ref-type>"},
             "rdf_zotero" =>   {"title" =>  '<dc:title>Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700', "type" =>  '<z:itemType>thesis</z:itemType>'}
}
      ti_data["6788245"] = 
          { "ris" =>           {"title" => 'TI  - Harry Potter and the half-blood prince',"type" =>'TY  - VIDEO'},
             "endnote" =>      {"title" => '%T Harry Potter and the half-blood prince', "type" =>  '%0 Film or Broadcast'},
             "endnote_xml" =>  {"title" => '<title>Harry Potter and the half-blood prince', "type" => "<ref-type name=\"Film or Broadcast\">21</ref-type>"},
             "rdf_zotero" =>   {"title" =>  '<dc:title>Harry Potter and the half-blood prince', "type" =>  '<z:itemType>videoRecording</z:itemType>'}
}
      ti_data["1676023"] = 
          { "ris" =>           {"title" => 'TI  - Middle Earth: being a map',"type" =>'TY  - MAP'},
            "endnote" =>       {"title" => '%T Middle Earth  being a map', "type" =>  '%0 Map'},
            "endnote_xml" =>   {"title" => '<title>Middle Earth: being a map', "type" => "<ref-type name=\"Map\">20</ref-type>"},
            "rdf_zotero" =>    {"title" =>  '<dc:title>Middle Earth: being a map', "type" =>  '<z:itemType>map</z:itemType>'}
}
      ti_ids.each   do  | id |
        ti_output[id] = {} 
        ti_output[id]["ris"] = ti_output[id]["endnote"] = ti_output[id]["endnote_xml"] = {} 
        ti_output[id]["rdf_zotero"] = {} 
        ti_output[id]["ris"] = @book_recs[id].export_as_ris()
        ti_output[id]["endnote"] = @book_recs[id].export_as_endnote()
        ti_output[id]["endnote_xml"] = @book_recs[id].export_as_endnote_xml()
        ti_output[id]["rdf_zotero"] = @book_recs[id].export_as_rdf_zotero()
      end 
      ti_ids.each   do |id| 
        ["endnote","ris","endnote_xml","rdf_zotero"].each   do |fmt| 
          ["title","type"].each   do |fld| 
             expect(ti_data[id]).not_to  be_nil, "You must supply data to match for bib id:#{id}." 
             expect(ti_data[id][fmt]).not_to  be_nil, "You must supply format data to match for bib id:#{id} for format '#{fmt}'." 
             expect(ti_data[id][fmt][fld]).not_to  be_nil, "You must supply field text to match for bib id:#{id}, #{fld} in format '#{fmt}' properly." 
             expect(ti_output[id][fmt]).to  include(ti_data[id][fmt][fld]), "For bib id:#{id},should output the #{fld} in format '#{fmt}' properly." 
          end
        end
       end
    end # end of "should export the title and type in multiple formats correctly"

#185 | 10055679 | endnote |  '%L  Mann Library  SF98.A5 M35 2017' |
#186 | 10055679 | ris |  'CN - Mann Library  SF98.A5 M35 2017' |
#188 | 10055679 | endnote_xml |  '<call-num>Mann Library  SF98.A5 M35 2017</call-num>' | 
#187 | 10055679 | rdf_zotero |  'Mann Library  SF98.A5 M35 2017' |
# SN  - 9781426217661  1426217668
# KW  - Chickens Marketing
    it "should export the call number, and isbn in multiple formats correctly" do
      ti_ids = [ "10055679" ]
      ti_data = {} 
      ti_output = {} 
      ti_ids.each   do  | id |
        ti_output[id] = {} 
        ti_output[id]["ris"] = ti_output[id]["endnote"] = ti_output[id]["endnote_xml"] = {} 
        ti_output[id]["rdf_zotero"] = {} 
        expect(@book_recs[id]).not_to  be_nil, "You must supply a MockMarcDocument to match for bib id:#{id}." 
        ti_output[id]["ris"] = @book_recs[id].export_as_ris()
        ti_output[id]["endnote"] = @book_recs[id].export_as_endnote()
        ti_output[id]["endnote_xml"] = @book_recs[id].export_as_endnote_xml()
        ti_output[id]["rdf_zotero"] = @book_recs[id].export_as_rdf_zotero()
      end 
     ti_data["10055679"] = 
          { "ris" =>  {'callnumber' => 'CN  - Mann Library  SF98.A5 M35 2017','isbn' =>'9781426217661  1426217668',"kw" =>"KW  - Chickens Marketing"},
          "endnote" =>{'callnumber' => '%L  Mann Library  SF98.A5 M35 2017' ,'isbn' =>'%@ 9781426217661',"kw" =>"%K Chickens Marketing"},
          "endnote_xml"=>{'callnumber'=>'<call-num>Mann Library  SF98.A5 M35 2017</call-num>','isbn' =>'<isbn>9781426217661  ; 1426217668 </isbn>',"kw" =>"<keyword>Chickens Marketing. </keyword>"},
          "rdf_zotero" =>   {'callnumber' => 'Mann Library  SF98.A5 M35 2017','isbn' =>
             Set.new(['<dc:identifier>ISBN 1426217668 </dc:identifier>','<dc:identifier>ISBN 9781426217661 </dc:identifier>']),
             "kw" =>"<dc:subject>Chickens Marketing. </dc:subject>"}
          }
      ti_ids.each   do |id| 
        ["ris","endnote","endnote_xml","rdf_zotero"].each   do |fmt| 
          ["callnumber","isbn","kw"].each   do |fld| 
             expect(ti_data[id]).not_to  be_nil, "You must supply data to match for bib id:#{id}." 
             expect(ti_data[id][fmt]).not_to  be_nil, "You must supply format data to match for bib id:#{id} for format '#{fmt}'." 
             expect(ti_data[id][fmt][fld]).not_to  be_nil, "You must supply field text to match for bib id:#{id}, #{fld} in format '#{fmt}' properly." 
             if ti_data[id][fmt][fld].is_a? Set
               ti_data[id][fmt][fld].each {|exp|
                 expect(ti_output[id][fmt]).to include(exp),"Bib id:#{id},should output #{fld} in format '#{fmt}'  did not match #{exp} properly." 
               }
             else
               expect(ti_output[id][fmt]).to include(ti_data[id][fmt][fld]),"Bib id:#{id},should output the #{fld} in format '#{fmt}' properly." 
             end
          end
        end
       end
    end

    it "should export the author,publisher,date,place in multiple formats correctly" do
      ti_ids = [ "1378974","3261564","5494906","6788245","9496646","9939352" ]
      ti_data = {} 
      ti_output = {} 
      ti_ids.each   do  | id |
        ti_output[id] = {} 
        ti_output[id]["ris"] = ti_output[id]["endnote"] = ti_output[id]["endnote_xml"] = {} 
        ti_output[id]["rdf_zotero"] = {} 
        expect(@book_recs[id]).not_to  be_nil, "You must supply a MockMarcDocument to match for bib id:#{id}." 
        ti_output[id]["ris"] = @book_recs[id].export_as_ris()
        ti_output[id]["endnote"] = @book_recs[id].export_as_endnote()
        ti_output[id]["endnote_xml"] = @book_recs[id].export_as_endnote_xml()
        ti_output[id]["rdf_zotero"] = @book_recs[id].export_as_rdf_zotero()
      end 
     ti_data["1378974"] = 
          { "ris" =>          {'author' => 'AU  - Condie, Carol Joy','year' =>'PY  - 1954',
                               'publisher' => 'PB  - Cornell Univ','place' => 'CY  - [Ithaca, N.Y.]'},
            "endnote" =>      {'author' => '%A Condie, Carol Joy', 'year' =>  '%D  1954',
                               'publisher' => '%I Cornell Univ','place' => '%C [Ithaca, N.Y.]'},
            "endnote_xml" =>  {'author' => '<author>Condie, Carol Joy', 'year' => '<year>1954</year',
                               'publisher' => '<publisher>Cornell Univ','place' => '<pub-location>[Ithaca, N.Y.]'},
            "rdf_zotero" =>   {'author' => '<foaf:surname>Condie</foaf:surname>','year'=>'<dc:date>1954</dc:date>',
                               'publisher' => '<foaf:name>Cornell Univ','place' => '<vcard:locality>[Ithaca, N.Y.]'}
          }
     ti_data["5494906"] = 
          { "ris" =>           {'author'=>'AU  - Gauger, Wilhelm Peter Joachim' ,'year'=> 'PY  - 1965','publisher'=>'PB  - Freie Universität Berlin','place'=>'CY  - Berlin' },
          "endnote"=>          {'author'=>'%A Gauger, Wilhelm Peter Joachim' ,'year'=> '%D 1965','publisher'=>'%I Freie Universität Berlin','place'=>'%C Berlin'} ,
          "endnote_xml"=>      {'author'=>'author>Gauger, Wilhelm Peter Joachim</author>' ,'year'=> '<date>1965</date>','publisher' =>'<publisher>Ernst-Reuter-Gesellschaft</publisher>','place'=>'pub-location>Berlin</pub-location>' },
          "rdf_zotero"=>       {'author'=>'<foaf:surname>Gauger</foaf:surname>' ,'year'=> '<dc:date>1965</dc:date>','publisher'=>'<foaf:name>Freie Universität Berlin</foaf:name>','place'=>'<vcard:locality>Berlin</vcard:locality>' }
          }
     ti_data["3261564"] = 
          { "ris" =>           {'author'=> 'AU  - Cakrabarttī, Utpalendu' , 'year'=> 'PY  - 1983' ,'publisher'=> 'PB  -  INRECO' ,'place'=> 'CY  - Calcutta' },
            "endnote" =>       {'author'=> '%A Cakrabarttī, Utpalendu' ,'year'=> '%D 1983' ,'publisher'=> '%I INRECO' ,'place'=> '%C Calcutta' },
            "endnote_xml" =>   {'author'=> '<author>Cakrabarttī, Utpalendu</author>' ,'year'=> '<year>1983</year>' ,'publisher'=> '<publisher>INRECO</publisher>' ,'place'=> '<pub-location>Calcutta</pub-location>' }, 
            "rdf_zotero"=>     {'author'=>'<foaf:surname>Cakrabarttī</foaf:surname>','year'=>'<dc:date>1983</dc:date>','publisher'=>'<foaf:name>INRECO</foaf:name>','place'=>'<vcard:locality>Calcutta</vcard:locality>' },
          }
     ti_data["6788245"] = 
          {"ris" =>             {"author" => 'AU  - Warner Bros. Pictures' ,'year' =>  'PY  - 2009' ,'publisher' =>  'PB  -  Warner Home Video' ,'place' => 'CY  - Burbank, CA' },
          "endnote" =>          {"author" => '%E Radcliffe, Daniel' ,'year' =>  '%D 2009' ,'publisher' =>  '%I Warner Home Video' ,'place' => '%C Burbank, CA' },
          "endnote_xml" =>      {"author" => '<author>Radcliffe, Daniel</author>' ,'year' =>  '<year>2009</year>' ,'publisher' =>  '<publisher>Warner Home Video</publisher>','place' =>'<pub-location>Burbank, CA</pub-location>' },
          "rdf_zotero" =>       {"author" => '<foaf:surname>Radcliffe</foaf:surname>' ,'year' =>  '<dc:date>2009</dc:date>' ,'publisher' =>  '<foaf:name>Warner Home Video</foaf:name>','place' =>'<vcard:locality>Burbank, CA</vcard:locality>' },
          }

     ti_data["9939352"] = 
          {"ris" => {"author" => 'AU  - Gray, Afsaneh' ,'year' =>  'PY  - 2017' ,'publisher' => 'PB  -  Oberon Books' ,'place' => 'CY  - London' },
           "endnote" => {"author"=> '%A Gray, Afsaneh' ,'year' =>  '%D 2017' ,'publisher' => '%I Oberon Books' ,'place' => '%C London' },
           "endnote_xml"=> {"author"=>'author>Gray, Afsaneh</author>','year' =>'<date>2017</date>','publisher' =>'publisher>Oberon Books</publisher>','place' =>'pub-location>London</pub-location>' },
            "rdf_zotero"=> {"author"=>'<foaf:surname>Gray</foaf:surname>','year' =>'<dc:date>2017</dc:date>','publisher' =>'<foaf:name>Oberon Books</foaf:name>','place' =>'<vcard:locality>London</vcard:locality>' },
}
     ti_data["9496646"] = 
     { "ris" => {"author"=> 'AU  - Bindal, Ahmet' ,'year' => 'PY  - 2016' ,'publisher' => 'PB  -  Springer International Publishing' ,'place' => 'CY  - Cham'  },
       "endnote" => {"author"=> '%A Bindal, Ahmet' ,'year' => '%D 2016' ,'publisher' =>  '%I Springer International Publishing' ,'place' => '%C Cham'  },
       "endnote_xml" => {"author"=> '<author>Bindal, Ahmet</author>' ,'year' => '<year>2016</year>' ,'publisher' => '<publisher>Springer International Publishing</publisher>' ,'place' => '<pub-location>Cham</pub-location>'  }, 
       "rdf_zotero" => {"author"=> '<foaf:surname>Bindal</foaf:surname>' ,'year' => '<dc:date>2016</dc:date>' ,'publisher' => '<foaf:name>Springer International Publishing</foaf:name>' ,'place' => '<vcard:locality>Cham</vcard:locality>'   },
}

      ti_ids.each   do |id| 
        ["ris","endnote","endnote_xml","rdf_zotero"].each   do |fmt| 
          ["author","year","publisher","place"].each   do |fld| 
             expect(ti_data[id]).not_to  be_nil, "You must supply data to match for bib id:#{id}." 
             expect(ti_data[id][fmt]).not_to  be_nil, "You must supply format data to match for bib id:#{id} for format '#{fmt}'." 
             expect(ti_data[id][fmt][fld]).not_to  be_nil, "You must supply field text to match for bib id:#{id}, #{fld} in format '#{fmt}' properly." 
             expect(ti_output[id][fmt]).to  include(ti_data[id][fmt][fld]), "For bib id:#{id}, should output the #{fld} in format '#{fmt}' properly." 
          end
        end
       end
    end #end of "it should export au, pb,py"


  end # describe


end
