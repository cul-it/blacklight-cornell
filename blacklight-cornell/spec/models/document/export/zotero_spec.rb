# -*- encoding : utf-8 -*-

require "rails_helper"

RSpec.describe "Zotero RDF export" do
  include_context "marc export fixtures"
  include_context "folio source fixtures"

  let(:zotero_harness_class) do
    Class.new do
      include Blacklight::Document::Export::Zotero

      def initialize(values)
        @values = values
      end

      def export_title(separator:)
        @values[:title]
      end

      def export_format
        @values[:format]
      end

      def export_catalog_url
        @values[:catalog_url]
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

      def export_languages
        @values[:languages] || []
      end

      def export_keywords
        @values[:keywords] || []
      end

      def export_abstracts
        @values[:abstracts] || []
      end

      def export_access_url
        @values[:access_url]
      end

      def export_isbns
        @values[:isbns] || []
      end

      def export_doi
        @values[:doi]
      end

      def export_holdings_string(separator:)
        @values[:holdings]
      end

      def export_medium(_kind)
        @values[:medium]
      end

      def export_thesis_info
        @values[:thesis]
      end
    end
  end

  it "exports title and type mappings for MARC records" do
    ti_data = {
      "1001" => { title: "<dc:title>Reflections: the anthropological muse</dc:title>", type: "<z:itemType>book</z:itemType>" },
      "1676023" => { title: "<dc:title>Middle Earth: being a map", type: "<z:itemType>map</z:itemType>" },
      "3261564" => { title: "<dc:title>Debabrata Biśvāsa</dc:title>", type: "<z:itemType>audioRecording</z:itemType>" },
      "5494906" => { title: "<dc:title>Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700", type: "<z:itemType>thesis</z:itemType>" },
      "5558811" => { title: "<dc:title>Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament</dc:title>", type: "<z:itemType>book</z:itemType>" },
      "6788245" => { title: "<dc:title>Harry Potter and the half-blood prince", type: "<z:itemType>videoRecording</z:itemType>" }
    }

    ti_data.each do |id, data|
      output = @book_recs[id].export_as_rdf_zotero
      expect(output).to include(data[:title]), "For bib id:#{id}, should output the title properly."
      expect(output).to include(data[:type]), "For bib id:#{id}, should output the type properly."
    end
  end

  it "exports call numbers, isbn, and keywords for MARC records" do
    output = @book_recs["10055679"].export_as_rdf_zotero
    expect(output).to include("Mann Library  SF98.A5 M35 2017")
    expect(output).to include("<dc:identifier>ISBN 1426217668 </dc:identifier>")
    expect(output).to include("<dc:identifier>ISBN 9781426217661 </dc:identifier>")
    expect(output).to include("<dc:subject>Chickens Marketing. </dc:subject>")
  end

  it "exports author, publisher, year, and place for MARC records" do
    ti_data = {
      "1378974" => { author: "<foaf:surname>Condie</foaf:surname>", year: "<dc:date>1954</dc:date>", publisher: "<foaf:name>Cornell Univ", place: "<vcard:locality>[Ithaca, N.Y.]" },
      "3261564" => { author: "<foaf:surname>Cakrabarttī</foaf:surname>", year: "<dc:date>1983</dc:date>", publisher: "<foaf:name>INRECO</foaf:name>", place: "<vcard:locality>Calcutta</vcard:locality>" },
      "5494906" => { author: "<foaf:surname>Gauger</foaf:surname>", year: "<dc:date>1965</dc:date>", publisher: "<foaf:name>Freie Universität Berlin</foaf:name>", place: "<vcard:locality>Berlin</vcard:locality>" },
      "6788245" => { author: "<foaf:surname>Radcliffe</foaf:surname>", year: "<dc:date>2009</dc:date>", publisher: "<foaf:name>Warner Home Video</foaf:name>", place: "<vcard:locality>Burbank, CA</vcard:locality>" },
      "9496646" => { author: "<foaf:surname>Bindal</foaf:surname>", year: "<dc:date>2016</dc:date>", publisher: "<foaf:name>Springer International Publishing</foaf:name>", place: "<vcard:locality>Cham</vcard:locality>" },
      "9939352" => { author: "<foaf:surname>Gray</foaf:surname>", year: "<dc:date>2017</dc:date>", publisher: "<foaf:name>Oberon Books</foaf:name>", place: "<vcard:locality>London</vcard:locality>" }
    }

    ti_data.each do |id, data|
      output = @book_recs[id].export_as_rdf_zotero
      expect(output).to include(data[:author]), "For bib id:#{id}, should output the author properly."
      expect(output).to include(data[:year]), "For bib id:#{id}, should output the year properly."
      expect(output).to include(data[:publisher]), "For bib id:#{id}, should output the publisher properly."
      expect(output).to include(data[:place]), "For bib id:#{id}, should output the place properly."
    end
  end

  it "exports Zotero RDF using FOLIO records" do
    rdf = folio_document.export_as_rdf_zotero
    expect(rdf).to include("<dc:title>AI AND ADA: ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE</dc:title>")
    expect(rdf).to include("<z:itemType>book</z:itemType>")
    expect(rdf).to include("<foaf:name>FIRST HILL BOOKS</foaf:name>")
    expect(rdf).to include("<foaf:surname>SELIGMAN</foaf:surname>")
    expect(rdf).to include("<foaf:givenname>MARK</foaf:givenname>")
    expect(rdf).to include("<rdf:value>Olin Library  PS3600 .S35 2026</rdf:value>")
    expect(rdf).to include("http://catalog.library.cornell.edu/catalog/17199945")
  end

  it "exports video recording RDF with contributors and medium" do
    doc = zotero_harness_class.new(
      title: "Video Work",
      format: "Video",
      catalog_url: "http://catalog.test/video",
      contributors: {
        primary_authors: ["Doe, Jane"],
        editors: ["Editor, One"]
      },
      pub_data: { place: "Ithaca", publisher: "Video Pub", date: "2021" },
      edition: "Special edition",
      languages: ["English"],
      keywords: ["Keyword"],
      abstracts: ["Abstract text"],
      access_url: "http://example.com/video",
      isbns: ["9999"],
      doi: "10.9999/video",
      holdings: "Library  ABC",
      medium: "DVD"
    )

    xml = doc.export_as_rdf_zotero

    expect(xml).to include("<z:itemType>videoRecording</z:itemType>")
    expect(xml).to include("<z:medium>DVD</z:medium>")
    expect(xml).to include("<foaf:surname>Doe</foaf:surname>")
    expect(xml).to include("<foaf:givenname>Jane</foaf:givenname>")
    expect(xml).to include("<foaf:surname>Editor</foaf:surname>")
    expect(xml).to include("<dc:description>http://catalog.test/video</dc:description>")
  end

  it "exports thesis RDF with relators and thesis details" do
    doc = zotero_harness_class.new(
      title: "Thesis Work",
      format: "Thesis",
      catalog_url: "http://catalog.test/thesis",
      contributors: {
        primary_authors: [],
        primary_corporate_authors: ["Corp Org"],
        editors: []
      },
      relators: { "Relator, Role" => ["edt"] },
      pub_data: { place: "Ithaca", publisher: nil, date: "2022" },
      thesis: { type: "Ph.D.", inst: "Thesis Inst" },
      access_url: "http://example.com/thesis",
      keywords: ["Keyword"],
      abstracts: ["Abstract text"],
      holdings: "Library  ABC",
      doi: "10.2222/thesis"
    )

    xml = doc.export_as_rdf_zotero

    expect(xml).to include("<z:itemType>thesis</z:itemType>")
    expect(xml).to include("<z:type>Ph.D.</z:type>")
    expect(xml).to include("<foaf:name>Thesis Inst</foaf:name>")
    expect(xml).to include("<foaf:surname>Corp Org</foaf:surname>")
    expect(xml).to include("<foaf:surname>Relator</foaf:surname>")
  end

  it "exports audio recording RDF with performers" do
    doc = zotero_harness_class.new(
      title: "Audio Work",
      format: "Musical Recording",
      catalog_url: "http://catalog.test/audio",
      contributors: {
        primary_authors: ["Performer, One"]
      },
      pub_data: { place: "Ithaca", publisher: "Audio Pub", date: "2020" },
      medium: "CD"
    )

    xml = doc.export_as_rdf_zotero

    expect(xml).to include("<z:itemType>audioRecording</z:itemType>")
    expect(xml).to include("<z:medium>CD</z:medium>")
    expect(xml).to include("<z:performers>")
  end

  it "exports map RDF with cartographers" do
    doc = zotero_harness_class.new(
      title: "Map Work",
      format: "Map or Globe",
      catalog_url: "http://catalog.test/map",
      contributors: {
        primary_authors: ["Cartographer, One"]
      }
    )

    xml = doc.export_as_rdf_zotero

    expect(xml).to include("<z:itemType>map</z:itemType>")
    expect(xml).to include("<z:cartographers>")
  end

  it "maps relator codes with a fallback" do
    doc = zotero_harness_class.new(title: "Relator Test", format: "Book", catalog_url: "")
    expect(doc.relator_to_zotero("aut")).to eq("authors")
    expect(doc.relator_to_zotero("zzz")).to eq("contributors")
  end
end
