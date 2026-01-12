# -*- encoding : utf-8 -*-

require "rails_helper"

RSpec.describe "RIS export" do
  include_context "marc export fixtures"
  include_context "folio source fixtures"

  let(:ris_harness_class) do
    Class.new do
      include Blacklight::Document::Export::Ris

      def initialize(values)
        @values = values
      end

      def exportable_record?
        @values.fetch(:exportable, true)
      end

      def export_format
        @values[:format]
      end

      def export_online?
        @values[:online]
      end

      def export_title(separator:)
        @values[:title]
      end

      def export_contributors
        @values[:contributors] || {}
      end

      def export_publication_data
        @values[:pub_data] || {}
      end

      def export_thesis_info
        @values[:thesis]
      end

      def export_edition
        @values[:edition]
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

      def export_doi
        @values[:doi]
      end

      def export_keywords
        @values[:keywords] || []
      end

      def export_notes
        @values[:notes] || []
      end

      def export_abstracts
        @values[:abstracts] || []
      end

      def export_holdings
        @values[:holdings] || []
      end

      def export_isbns
        @values[:isbns] || []
      end
    end
  end

  it "exports a simple MARC record correctly" do
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

  it "exports a typical MARC book record correctly" do
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

  it "exports a typical MARC ebook record correctly" do
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

  it "exports title and type mappings for MARC records" do
    ti_data = {
      "1001" => { title: "TI  - Reflections: the anthropological muse", type: "TY  - BOOK" },
      "1676023" => { title: "TI  - Middle Earth: being a map", type: "TY  - MAP" },
      "3261564" => { title: "TI  - Debabrata Biśvāsa", type: "TY  - SOUND" },
      "5494906" => { title: "TI  - Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700", type: "TY  - THES" },
      "5558811" => { title: "TI  - Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament", type: "TY  - EBOOK" },
      "6788245" => { title: "TI  - Harry Potter and the half-blood prince", type: "TY  - VIDEO" }
    }

    ti_data.each do |id, data|
      output = @book_recs[id].export_as_ris
      expect(output).to include(data[:title]), "For bib id:#{id}, should output the title properly."
      expect(output).to include(data[:type]), "For bib id:#{id}, should output the type properly."
    end
  end

  it "exports call numbers, isbn, and keywords for MARC records" do
    output = @book_recs["10055679"].export_as_ris
    expect(output).to include("CN  - Mann Library  SF98.A5 M35 2017")
    expect(output).to include("9781426217661  1426217668")
    expect(output).to include("KW  - Chickens Marketing")
  end

  it "exports author, publisher, year, and place for MARC records" do
    ti_data = {
      "1378974" => { author: "AU  - Condie, Carol Joy", year: "PY  - 1954", publisher: "PB  - Cornell Univ", place: "CY  - [Ithaca, N.Y.]" },
      "3261564" => { author: "AU  - Cakrabarttī, Utpalendu", year: "PY  - 1983", publisher: "PB  - INRECO", place: "CY  - Calcutta" },
      "5494906" => { author: "AU  - Gauger, Wilhelm Peter Joachim", year: "PY  - 1965", publisher: "PB  - Freie Universität Berlin", place: "CY  - Berlin" },
      "6788245" => { author: "AU  - Warner Bros. Pictures", year: "PY  - 2009", publisher: "PB  - Warner Home Video", place: "CY  - Burbank, CA" },
      "9496646" => { author: "AU  - Bindal, Ahmet", year: "PY  - 2016", publisher: "PB  - Springer International Publishing", place: "CY  - Cham" },
      "9939352" => { author: "AU  - Gray, Afsaneh", year: "PY  - 2017", publisher: "PB  - Oberon Books", place: "CY  - London" }
    }

    ti_data.each do |id, data|
      output = @book_recs[id].export_as_ris
      expect(output).to include(data[:author]), "For bib id:#{id}, should output the author properly."
      expect(output).to include(data[:year]), "For bib id:#{id}, should output the year properly."
      expect(output).to include(data[:publisher]), "For bib id:#{id}, should output the publisher properly."
      expect(output).to include(data[:place]), "For bib id:#{id}, should output the place properly."
    end
  end

  it "exports RIS using FOLIO records" do
    ris = folio_document.export_as_ris
    expect(ris).to include("TY  - BOOK")
    expect(ris).to include("AU  - SELIGMAN, MARK")
    expect(ris).to include("TI  - AI AND ADA: ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE")
    expect(ris).to include("PY  - 2026")
    expect(ris).to include("PB  - FIRST HILL BOOKS")
    expect(ris).to include("CN  - Olin Library  PS3600 .S35 2026")
    expect(ris).to include("M2  - http://catalog.library.cornell.edu/catalog/17199945")
    expect(ris).to include("N1  - http://catalog.library.cornell.edu/catalog/17199945")
  end

  it "returns nil when the record is not exportable" do
    doc = ris_harness_class.new(exportable: false, format: "Book")
    expect(doc.export_as_ris).to be_nil
  end

  it "exports EBOOK with corporate authors and metadata" do
    doc = ris_harness_class.new(
      format: "Book",
      online: true,
      title: "Online Book",
      contributors: {
        primary_authors: [],
        primary_corporate_authors: ["Corp One"],
        secondary_corporate_authors: ["Corp Two"],
        editors: []
      },
      pub_data: { publisher: "Corp Pub", place: "Ithaca", date: "2024" },
      edition: "Second edition",
      languages: ["English"],
      access_url: "http://example.com",
      catalog_url: "http://catalog.test/ebook",
      doi: "10.5555/ebook",
      keywords: ["Keyword One"],
      notes: ["Note text"],
      abstracts: ["Abstract text"],
      holdings: ["Library  ABC"],
      isbns: ["1234"]
    )

    ris = doc.export_as_ris

    expect(ris).to include("TY  - EBOOK")
    expect(ris).to include("AU  - Corp One")
    expect(ris).to include("A1  - Corp Two")
    expect(ris).to include("PY  - 2024")
    expect(ris).to include("PB  - Corp Pub")
    expect(ris).to include("CY  - Ithaca")
    expect(ris).to include("ET  - Second edition")
    expect(ris).to include("LA  - English")
    expect(ris).to include("UR  - http://example.com")
    expect(ris).to include("M2  - http://catalog.test/ebook")
    expect(ris).to include("DO  - 10.5555/ebook")
    expect(ris).to include("KW  - Keyword One")
    expect(ris).to include("N1  - Note text")
    expect(ris).to include("N2  - Abstract text")
    expect(ris).to include("CN  - Library  ABC")
    expect(ris).to include("SN  - 1234")
  end

  it "exports thesis metadata with editors and multiple authors" do
    doc = ris_harness_class.new(
      format: "Thesis",
      online: false,
      title: "Thesis Work",
      contributors: {
        primary_authors: ["Author One", "Author Two"],
        editors: ["Editor One"]
      },
      pub_data: { publisher: "Ignored Pub", place: "Boston", date: "2020" },
      thesis: { inst: "Thesis Inst", type: "Ph.D." }
    )

    ris = doc.export_as_ris

    expect(ris).to include("TY  - THES")
    expect(ris).to include("AU  - Author One")
    expect(ris).to include("A1  - Author Two")
    expect(ris).to include("ED  - Editor One")
    expect(ris).to include("PB  - Thesis Inst")
    expect(ris).to include("CY  - Boston")
    expect(ris).to include("M3  - Ph.D.")
  end

  it "exports Mendeley and Zotero via the RIS formatter" do
    doc = ris_harness_class.new(format: "Book", online: false, title: "Shared Export")
    expect(doc.export_as_mendeley).to include("TY  - BOOK")
    expect(doc.export_as_zotero).to include("TY  - BOOK")
  end
end
