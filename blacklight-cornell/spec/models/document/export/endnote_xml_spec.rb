# -*- encoding : utf-8 -*-

require "rails_helper"

RSpec.describe "Endnote XML export" do
  include_context "marc export fixtures"
  include_context "folio source fixtures"

  let(:endnote_xml_harness_class) do
    Class.new do
      include Blacklight::Document::Export::EndnoteXml

      def initialize(values)
        @values = values
      end

      def exportable_record?
        @values.fetch(:exportable, true)
      end

      def export_title(separator:)
        @values[:title]
      end

      def export_format
        @values[:format]
      end

      def export_contributors
        @values[:contributors] || {}
      end

      def export_relators
        @values[:relators] || {}
      end

      def export_publication_data
        @values[:pub_data] || {}
      end

      def export_edition
        @values[:edition]
      end

      def export_keywords
        @values[:keywords] || []
      end

      def export_abstracts
        @values[:abstracts] || []
      end

      def export_notes
        @values[:notes] || []
      end

      def export_isbns
        @values[:isbns] || []
      end

      def export_holdings_string(separator:)
        @values[:holdings]
      end

      def export_doi
        @values[:doi]
      end

      def export_thesis_info
        @values[:thesis]
      end

      def export_languages
        @values[:languages] || []
      end

      def export_access_url
        @values[:access_url]
      end

      def export_catalog_url
        @values[:catalog_url]
      end
    end
  end

  it "exports title and type mappings for MARC records" do
    ti_data = {
      "1001" => { title: "<title>Reflections: the anthropological muse</title>", type: "<ref-type name=\"Book\">6</ref-type>" },
      "1676023" => { title: "<title>Middle Earth: being a map", type: "<ref-type name=\"Map\">20</ref-type>" },
      "3261564" => { title: "<title>Debabrata Biśvāsa</title>", type: "<ref-type name=\"Music\">61</ref-type>" },
      "5494906" => { title: "<title>Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700</title>", type: "<ref-type name=\"Thesis\">32</ref-type>" },
      "5558811" => { title: "<title>Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament</title>", type: "<ref-type name=\"Book\">6</ref-type>" },
      "6788245" => { title: "<title>Harry Potter and the half-blood prince", type: "<ref-type name=\"Film or Broadcast\">21</ref-type>" }
    }

    ti_data.each do |id, data|
      output = @book_recs[id].export_as_endnote_xml
      expect(output).to include(data[:title]), "For bib id:#{id}, should output the title properly."
      expect(output).to include(data[:type]), "For bib id:#{id}, should output the type properly."
    end
  end

  it "exports call numbers, isbn, and keywords for MARC records" do
    output = @book_recs["10055679"].export_as_endnote_xml
    expect(output).to include("<call-num>Mann Library  SF98.A5 M35 2017</call-num>")
    expect(output).to include("<isbn>9781426217661  ; 1426217668 </isbn>")
    expect(output).to include("<keyword>Chickens Marketing. </keyword>")
  end

  it "exports author, publisher, year, and place for MARC records" do
    ti_data = {
      "1378974" => { author: "<author>Condie, Carol Joy", year: "<year>1954</year", publisher: "<publisher>Cornell Univ", place: "<pub-location>[Ithaca, N.Y.]" },
      "3261564" => { author: "<author>Cakrabarttī, Utpalendu</author>", year: "<year>1983</year>", publisher: "<publisher>INRECO</publisher>", place: "<pub-location>Calcutta</pub-location>" },
      "5494906" => { author: "author>Gauger, Wilhelm Peter Joachim</author>", year: "<date>1965</date>", publisher: "<publisher>Ernst-Reuter-Gesellschaft</publisher>", place: "pub-location>Berlin</pub-location>" },
      "6788245" => { author: "<author>Radcliffe, Daniel</author>", year: "<year>2009</year>", publisher: "<publisher>Warner Home Video</publisher>", place: "<pub-location>Burbank, CA</pub-location>" },
      "9496646" => { author: "<author>Bindal, Ahmet</author>", year: "<year>2016</year>", publisher: "<publisher>Springer International Publishing</publisher>", place: "<pub-location>Cham</pub-location>" },
      "9939352" => { author: "author>Gray, Afsaneh</author>", year: "<date>2017</date>", publisher: "publisher>Oberon Books</publisher>", place: "pub-location>London</pub-location>" }
    }

    ti_data.each do |id, data|
      output = @book_recs[id].export_as_endnote_xml
      expect(output).to include(data[:author]), "For bib id:#{id}, should output the author properly."
      expect(output).to include(data[:year]), "For bib id:#{id}, should output the year properly."
      expect(output).to include(data[:publisher]), "For bib id:#{id}, should output the publisher properly."
      expect(output).to include(data[:place]), "For bib id:#{id}, should output the place properly."
    end
  end

  it "exports Endnote XML using FOLIO records" do
    endnote_xml = folio_document.export_as_endnote_xml
    expect(endnote_xml).to include('<ref-type name="Book">6</ref-type>')
    expect(endnote_xml).to include("<title>AI AND ADA: ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE</title>")
    expect(endnote_xml).to include("<publisher>FIRST HILL BOOKS</publisher>")
    expect(endnote_xml).to include("<author>SELIGMAN, MARK</author>")
    expect(endnote_xml).to include("<call-num>Olin Library  PS3600 .S35 2026</call-num>")
    expect(endnote_xml).to include("http://catalog.library.cornell.edu/catalog/17199945")
  end

  it "exports thesis metadata and auxiliary fields via the XML builder" do
    doc = endnote_xml_harness_class.new(
      title: "Thesis Title",
      format: "Thesis",
      contributors: {
        primary_authors: [],
        primary_corporate_authors: ["Corp Author"],
        secondary_authors: ["Secondary Author"],
        editors: ["Ed Editor"]
      },
      pub_data: { place: "Ithaca", publisher: nil, date: "1999" },
      edition: "First edition",
      keywords: ["Keyword One"],
      abstracts: ["Abstract text"],
      notes: ["Note text"],
      isbns: ["111"],
      holdings: "Library  ABC 123",
      doi: "10.1234/doi",
      thesis: { type: "Ph.D.", inst: "Cornell Univ", date: "1999" },
      languages: ["English"],
      access_url: "http://example.com",
      catalog_url: "http://catalog.test/record"
    )

    xml = doc.export_as_endnote_xml

    expect(xml).to include("<work-type>Ph.D.</work-type>")
    expect(xml).to include("<publisher>Cornell Univ</publisher>")
    expect(xml).to include("<pub-location>Ithaca</pub-location>")
    expect(xml).to include("<isbn>111</isbn>")
    expect(xml).to include("<call-num>Library  ABC 123</call-num>")
    expect(xml).to include("<electronic-resource-num>10.1234/doi</electronic-resource-num>")
    expect(xml).to include("<abstract>Abstract text</abstract>")
    expect(xml).to include("Note text")
    expect(xml).to include("http://catalog.test/record")
    expect(xml).to include("<language>English</language>")
    expect(xml).to include("<url>http://example.com</url>")
    expect(xml).to include("<author>Corp Author</author>")
    expect(xml).to include("<tertiary-authors>")
  end

  it "returns nil when the record is not exportable" do
    doc = endnote_xml_harness_class.new(exportable: false, format: "Book")
    expect(doc.export_as_endnote_xml).to be_nil
  end
end
