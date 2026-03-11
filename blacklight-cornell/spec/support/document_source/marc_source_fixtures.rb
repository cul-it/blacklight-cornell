# frozen_string_literal: true

RSpec.shared_context "marc source fixtures" do
  let(:marc_xml) do
    <<~XML
      <?xml version="1.0"?>
      <record xmlns="http://www.loc.gov/MARC21/slim">
        <leader>01575cjm a2200409 a 4500</leader>
        <controlfield tag="001">batman-1</controlfield>
        <datafield tag="100" ind1="1" ind2=" ">
          <subfield code="a">Elfman, Danny.</subfield>
        </datafield>
        <datafield tag="700" ind1="1" ind2="2">
          <subfield code="a">Brahms, Johannes.</subfield>
        </datafield>
        <datafield tag="700" ind1="1" ind2=" ">
          <subfield code="a">Burton, Tim</subfield>
          <subfield code="e">editor.</subfield>
        </datafield>
        <datafield tag="110" ind1="2" ind2=" ">
          <subfield code="a">Gotham Music Group</subfield>
        </datafield>
        <datafield tag="111" ind1="2" ind2=" ">
          <subfield code="a">Gotham Symposium</subfield>
        </datafield>
        <datafield tag="245" ind1="1" ind2="0">
          <subfield code="a">Batman</subfield>
          <subfield code="b">a film score</subfield>
          <subfield code="c">edited by Tim Burton.</subfield>
        </datafield>
        <datafield tag="250" ind1=" " ind2=" ">
          <subfield code="a">Second edition.</subfield>
        </datafield>
        <datafield tag="260" ind1=" " ind2=" ">
          <subfield code="a">Los Angeles, CA :</subfield>
          <subfield code="b">Omni Music Publishing,</subfield>
          <subfield code="c">[2016]</subfield>
        </datafield>
        <datafield tag="300" ind1=" " ind2=" ">
          <subfield code="a">1 videodisc (65 min.) :</subfield>
          <subfield code="b">sound, color ;</subfield>
          <subfield code="c">4 3/4 in.</subfield>
        </datafield>
        <datafield tag="347" ind1=" " ind2=" ">
          <subfield code="b">DVD videodisc</subfield>
        </datafield>
        <datafield tag="020" ind1=" " ind2=" ">
          <subfield code="a">9780989004718</subfield>
        </datafield>
        <datafield tag="020" ind1=" " ind2=" ">
          <subfield code="a">0989004716</subfield>
        </datafield>
        <datafield tag="022" ind1=" " ind2=" ">
          <subfield code="a">1234-5678.</subfield>
        </datafield>
        <datafield tag="024" ind1="7" ind2=" ">
          <subfield code="a">10.1234/batman</subfield>
          <subfield code="2">doi</subfield>
        </datafield>
        <datafield tag="502" ind1=" " ind2=" ">
          <subfield code="a">Thesis--Cornell Univ.,2016.</subfield>
        </datafield>
        <datafield tag="500" ind1=" " ind2=" ">
          <subfield code="a">Includes composer notes.</subfield>
        </datafield>
        <datafield tag="505" ind1=" " ind2=" ">
          <subfield code="a">Suite and reprise.</subfield>
        </datafield>
        <datafield tag="520" ind1=" " ind2=" ">
          <subfield code="a">A symphonic score for the film.</subfield>
        </datafield>
        <datafield tag="650" ind1=" " ind2="0">
          <subfield code="a">Motion picture music</subfield>
          <subfield code="x">Scores</subfield>
        </datafield>
        <datafield tag="600" ind1="1" ind2="1">
          <subfield code="a">Elfman, Danny</subfield>
          <subfield code="d">1953-</subfield>
        </datafield>
      </record>
    XML
  end

  let(:marc_source) do
    {
      "record_dates_display" => [
        "{\"bib\":\"2021-06-18T14:11:20.924\",\"holdings\":{\"10246000\":\"2021-06-19T11:13:38.580\"}}"
      ],

      "author_display" => "Elfman, Danny.",

      "opensearch_display" => [
        "Elfman, Danny.",
        "Batman",
        "Motion picture music > Scores",
        "Orchestral music > Scores",
        "Motion picture music",
        "Scores"
      ],

      "author_json" => [
        "{\"name1\":\"Elfman, Danny.\",\"search1\":\"Elfman, Danny.\",\"relator\":\"\",\"type\":\"Personal Name\",\"authorizedForm\":true}"
      ],

      "title_display"       => "Batman",
      "fulltitle_display"   => "Batman",
      "subtitle_display"    => "",
      "title_responsibility_display" => ["Danny Elfman."],

      "subject_display" => [
        "Motion picture music > Scores",
        "Orchestral music > Scores",
        "Motion picture music",
        "Scores"
      ],

      "pub_info_display" => [
        "Los Angeles, CA : Omni Music Publishing, [2016]"
      ],
      "publisher_display" => ["Omni Music Publishing"],
      "pub_copy_display"  => ["©2016"],
      "pub_date_display"  => ["2016"],

      "isbn_display" => [
        "9780989004718",
        "0989004716"
      ],

      "edition_display" => ["Orchestral score."],

      "description_display" => [
        "1 score (10 unnumbered pages, 364 pages) ; 31 cm"
      ],

      "notes_display" => [
        "\"In full score\"--Cover.",
        "Duration: 75 minutes.",
        "Notes on the music by the composer (unnumbered page 7)."
      ],

      "instrumentation_display" => ["For orchestra"],

      "callnumber_display" => [
        "M1527.E374 B37 2016 +"
      ],

      "availability_json" => {
        "available" => true,
        "availAt" => {
          "Cox Library of Music and Dance" => "M1527.E374 B37 2016 +"
        }
      },

      "items_json" => {
        "234234235-f1b8-4b8a-b6fb-gd2345252256" => [
          {
            "id" => "c609d365-46d1-4555-a820-ef80e67781ad",
            "barcode" => "31924124175948",
            "call" => "M1527.E374 B37 2016 +",
            "status" => { "status" => "Available" },
            "active" => true
          }
        ]
      },
      "source" => "MARC",
      "format" => ["Musical Score"],
      "type"   => "Catalog",
      "online" => ["Online"],
      "marc_display" => marc_xml
    }
  end

  let(:marc_document) { SolrDocument.new(marc_source) }
end
