# -*- encoding : utf-8 -*-

require "rails_helper"

RSpec.describe "RIS export" do
  include_context "marc export fixtures"
  include_context "folio source fixtures"

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
end
