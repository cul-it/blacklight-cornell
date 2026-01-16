# -*- encoding : utf-8 -*-

require "rails_helper"

RSpec.describe "Endnote export" do
  include_context "marc export fixtures"
  include_context "folio source fixtures"

  it "exports an Endnote record correctly for MARC" do
    endnote_file = @music_record.export_as_endnote
    endnote_entries = Hash.new { |hash, key| hash[key] = Set.new }
    endnote_file.each_line do |line|
      line =~ /\%(..?) (.*)$/
      endnote_entries[$1] << $2
    end

    expect(endnote_entries["0"]).to eq(Set.new(["Music"]))
    expect(endnote_entries["D"]).to eq(Set.new(["2001"]))
    expect(endnote_entries["C"]).to eq(Set.new(["[United States]"]))
    expect(endnote_entries["E"]).to eq(Set.new(["Greer, Lowell ", "Lubin, Steven ", "Chase, Stephanie ", "Chase, Stepehn ", "Chaste, Stepehn ", "Brahms, Johannes ", "Beethoven, Ludwig van ", "Krufft, Nikolaus von "]))
    expect(endnote_entries["I"]).to eq(Set.new(["Harmonia Mundi USA"]))
    expect(endnote_entries["T"]).to eq(Set.new(["Music for horn "]))
    expect(Set.new(endnote_entries.keys)).to eq(Set.new(["0", "E", "T", "I", "C", "D", "Z", nil]))
  end

  it "exports title and type mappings for MARC records" do
    ti_data = {
      "1001" => { title: "%T Reflections  the anthropological muse", type: "%0 Book" },
      "1676023" => { title: "%T Middle Earth  being a map", type: "%0 Map" },
      "3261564" => { title: "%T Debabrata Biśvāsa", type: "%0 Music" },
      "5494906" => { title: "%T Geschlechter, Liebe und Ehe in der Auffassung von Londoner Zeitschriften um 1700", type: "%0 Thesis" },
      "5558811" => { title: "%T Mamusse wunneetupanatamwe Up-Biblum God naneeswe Nukkone Testament kah wonk Wusku Testament", type: "%0 Electronic Book" },
      "6788245" => { title: "%T Harry Potter and the half-blood prince", type: "%0 Film or Broadcast" }
    }

    ti_data.each do |id, data|
      output = @book_recs[id].export_as_endnote
      expect(output).to include(data[:title]), "For bib id:#{id}, should output the title properly."
      expect(output).to include(data[:type]), "For bib id:#{id}, should output the type properly."
    end
  end

  it "exports call numbers, isbn, and keywords for MARC records" do
    output = @book_recs["10055679"].export_as_endnote
    expect(output).to include("%L Mann Library  SF98.A5 M35 2017")
    expect(output).to include("%@ 9781426217661")
    expect(output).to include("%K Chickens Marketing")
  end

  it "exports author, publisher, year, and place for MARC records" do
    ti_data = {
      "1378974" => { author: "%A Condie, Carol Joy", year: "%D  1954", publisher: "%I Cornell Univ", place: "%C [Ithaca, N.Y.]" },
      "3261564" => { author: "%A Cakrabarttī, Utpalendu", year: "%D 1983", publisher: "%I INRECO", place: "%C Calcutta" },
      "5494906" => { author: "%A Gauger, Wilhelm Peter Joachim", year: "%D 1965", publisher: "%I Freie Universität Berlin", place: "%C Berlin" },
      "6788245" => { author: "%E Radcliffe, Daniel", year: "%D 2009", publisher: "%I Warner Home Video", place: "%C Burbank, CA" },
      "9496646" => { author: "%A Bindal, Ahmet", year: "%D 2016", publisher: "%I Springer International Publishing", place: "%C Cham" },
      "9939352" => { author: "%A Gray, Afsaneh", year: "%D 2017", publisher: "%I Oberon Books", place: "%C London" }
    }

    ti_data.each do |id, data|
      output = @book_recs[id].export_as_endnote
      expect(output).to include(data[:author]), "For bib id:#{id}, should output the author properly."
      expect(output).to include(data[:year]), "For bib id:#{id}, should output the year properly."
      expect(output).to include(data[:publisher]), "For bib id:#{id}, should output the publisher properly."
      expect(output).to include(data[:place]), "For bib id:#{id}, should output the place properly."
    end
  end

  it "exports Endnote using FOLIO records" do
    endnote = folio_document.export_as_endnote
    expect(endnote).to include("%0 Book")
    expect(endnote).to include("%A SELIGMAN, MARK")
    expect(endnote).to include("%T AI AND ADA ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE")
    expect(endnote).to include("%I FIRST HILL BOOKS")
    expect(endnote).to include("%D 2026")
    expect(endnote).to include("%L Olin Library  PS3600 .S35 2026")
    expect(endnote).to include("%Z http://catalog.library.cornell.edu/catalog/17199945")
  end
end
