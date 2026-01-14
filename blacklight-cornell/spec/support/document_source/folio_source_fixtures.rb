# frozen_string_literal: true

RSpec.shared_context "folio source fixtures" do
  let(:folio_holdings_json) do
    {
      "2352352355m23424-873a-481b-a83e-gd2345252256" => {
        "hrid" => "17191228",
        "location" => {
          "code"  => "olin",
          "name"  => "Olin Library",
          "library" => "Olin Library",
          "hoursCode" => "olinuris",
          "id" => "kjb234235-1d59-42e6-9600-gd2345252256",
          "primaryServicePoint" => "gd2345252256-362d-45b6-bfae-639565a877f2"
        },
        "call" => "PS3600 .S35 2026",
        "items" => {
          "count" => 1,
          "unavail" => [
            {
              "id" => "gd2345252256-6208-4a27-9480-235423525",
              "status" => { "status" => "On order", "date" => 1764841038 }
            }
          ]
        },
        "order" => "On order as of 12/4/25",
        "circ"  => true,
        "active" => true
      }
    }
  end

  let(:folio_source) do
    {
      "record_dates_display" => ["{\"bib\":\"2025-12-04T14:37:17.000+00:00\",\"holdings\":{\"17191228\":\"2025-12-04T14:37:18.089+00:00\"}}"],
      "author_addl_display" => ["SELIGMAN, MARK"],
      "author_addl_json" => ["{\"name1\":\"SELIGMAN, MARK\",\"search1\":\"SELIGMAN, MARK\",\"type\":\"Personal Name\"}"],
      "opensearch_display" => [
        "SELIGMAN, MARK",
        "AI AND ADA: ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE."
      ],
      "fulltitle_display" => "AI AND ADA: ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE.",
      "title_display" => "AI AND ADA: ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE.",
      "title_sms_compat_display" => ["AI AND ADA: ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE."],
      "title_2letter_s" => ["11"],
      "title_1letter_s" => ["1"],
      "publisher_display" => ["FIRST HILL BOOKS"],
      "pub_info_display"  => ["FIRST HILL BOOKS, 2026."],
      "pub_date_display"  => ["2026"],
      "database_b" => false,
      "id" => "17199945",
      "bibid_display" => ["17199945"],
      "instance_id"   => "234kg243o7i2364-11a1-47b6-ae26-2342m3n4v2jv34",
      "item_count_i"  => 1,
      "bound_with_b"  => true,
      "holdings_json" => folio_holdings_json.to_json,
      "availability_json" => {
        "available" => false,
        "unavailAt" => { "Olin Library" => "On order as of 12/4/25" }
      },
      "items_json" => {
        "234234234-873a-234234-a83e-234234234" => [
          {
            "id"   => "23234234-2342342-234234-234234-23423423423424",
            "hrid" => "15569927",
            "location" => {
              "code"  => "olin",
              "name"  => "Olin Library",
              "library" => "Olin Library",
              "hoursCode" => "olinuris",
              "id" => "c8e127a3-1d59-42e6-9600-bbdffc13b373",
              "primaryServicePoint" => "23424352-13423423-23425-wer4-23434235252"
            },
            "permLocation" => "Olin Library",
            "loanType" => {
              "id" => "34232352-f324-2344-g424-234gjv234234",
              "name" => "Circulating"
            },
            "matType" => {
              "name" => "unspecified",
              "id" => "1234567-89100-1234-5678-910222342455"
            },
            "status" => { "status" => "On order", "date" => 1764841038 },
            "empty"  => true,
            "active" => true
          }
        ]
      },
      "blankenum_b" => true,
      "_version_" => 1851175447667146752,
      "timestamp" => "2025-12-11T02:01:19.609Z",
      "author_pers_roman_filing" => ["seligman mark"],
      "author_pers_filing"       => ["seligman mark"],
      "availability_facet" => [
        "Bound With: Empty Items",
        "On Order",
        "On order"
      ],
      "source" => "FOLIO",
      "author_facet" => ["SELIGMAN, MARK"],
      "location" => [
        "Olin Library",
        "Olin Library > Main Collection"
      ],
      "type" => "Catalog",
      "pub_date_facet"   => 2026,
      "pub_date_sort"    => 2026,
      "format_main_facet"=> "Book",
      "format"           => ["Book"],
      "online" => ["At the Library"]
    }
  end

  let(:folio_document) { SolrDocument.new(folio_source) }
end
