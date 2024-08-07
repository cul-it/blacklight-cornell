require 'rails_helper'

RSpec.describe SearchBuilder, type: :model do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
  let(:advanced_search_fields) { %w[all_fields title journaltitle author subject lc_callnum series publisher pubplace number isbnissn notes donor] }
  subject(:search_builder) { described_class.new scope }

  describe '#group_bools' do
    let(:params) {
      {
        q_row: ['curly', 'moe', 'larry'],
        boolean_row: ['AND', 'OR']
      }
    }

    it 'returns queries chained by expected booleans' do
      expect(search_builder.group_bools(params)).to eq('( (curly AND moe)  OR larry)')
    end

    context 'missing booleans' do
      let(:params) {
        {
          q_row: ['curly', 'moe', 'larry'],
          boolean_row: ['AND']
        }
      }

      it 'defaults missing booleans to "AND"' do
        expect(search_builder.group_bools(params)).to eq('( (curly AND moe)  AND larry)')
      end
    end
  end

  describe '#checkMixedQuoted' do
    let(:defined_search_fields) { advanced_search_fields.excluding('all_fields') }

    context 'multiple quoted terms' do
      let(:q) { '"apples and oranges" "chickens and geese"' }

      context 'search_field = all_fields' do
        it 'returns expected array of params' do
          blacklight_params = { q: q, search_field: 'all_fields' }
          expect(search_builder.checkMixedQuoted(blacklight_params)).to eq(['+quoted:"apples and oranges"',
                                                                            '+quoted:"chickens and geese"'])
        end
      end

      context 'search_field != all_fields' do
        it 'returns expected array of params' do
          defined_search_fields.each do |search_field|
            blacklight_params = { q: q, search_field: search_field }
            expect(search_builder.checkMixedQuoted(blacklight_params)).to eq(["+#{search_field}_quoted:\"apples and oranges\"",
                                                                              "+#{search_field}_quoted:\"chickens and geese\""])
          end
        end
      end
    end

    context 'multiple quoted terms with non-quoted terms' do
      let(:q) { 'paint "apples and oranges" water "chickens and geese" troubadours' }

      context 'search_field = all_fields' do
        it 'returns expected array of params' do
          blacklight_params = { q: q, search_field: 'all_fields' }
          expect(search_builder.checkMixedQuoted(blacklight_params)).to eq(['+paint',
                                                                            '+quoted:"apples and oranges"',
                                                                            '+water',
                                                                            '+quoted:"chickens and geese"',
                                                                            '+troubadours'])
        end
      end

      context 'search_field != all_fields' do
        it 'returns expected array of params' do
          defined_search_fields.each do |search_field|
            blacklight_params = { q: q, search_field: search_field }
            expect(search_builder.checkMixedQuoted(blacklight_params)).to eq(["+#{search_field}:paint",
                                                                              "+#{search_field}_quoted:\"apples and oranges\"",
                                                                              "+#{search_field}:water",
                                                                              "+#{search_field}_quoted:\"chickens and geese\"",
                                                                              "+#{search_field}:troubadours"])
          end
        end
      end
    end

    # TODO: Should a phrase with an odd number of quotation marks really be queried with a quoted solr field
    context 'odd number of quotation marks' do
      let(:q) { '"painting "things hello"hi' }

      context 'search_field = all_fields' do
        it 'returns expected array of params' do
          blacklight_params = { q: q, search_field: 'all_fields' }
          expect(search_builder.checkMixedQuoted(blacklight_params)).to eq(['+quoted:"painting "',
                                                                            '+things',
                                                                            '+hello',
                                                                            '+quoted:"hi'])
        end
      end

      context 'search_field != all_fields' do
        it 'returns expected array of params' do
          defined_search_fields.each do |search_field|
            blacklight_params = { q: q, search_field: search_field }
            expect(search_builder.checkMixedQuoted(blacklight_params)).to eq(["+#{search_field}_quoted:\"painting \"",
                                                                              "+#{search_field}:things",
                                                                              "+#{search_field}:hello",
                                                                              "+#{search_field}_quoted:\"hi"])
          end
        end
      end
    end
  end

  describe '#advsearch' do
    before do
      allow(search_builder).to receive(:blacklight_params) { blacklight_params }
    end

    context 'simple catalog search' do
      let(:q) { 'test1 test2 test3'}
      let(:blacklight_params) { { q: q, search_field: search_field } }
      let(:solr_params) { { q: q, sort: 'score desc, pub_date_sort desc, title_sort asc' } }

      context 'all_fields' do
        let(:search_field) { 'all_fields' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          # TODO: What's the difference between phrase and quoted?
          expect(solr_params[:q]).to eq('("test1" AND "test2"  AND "test3") OR phrase:"test1 test2 test3"')
        end
      end

      context 'title' do
        let(:search_field) { 'title' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('(+title:"test1" +title:"test2" +title:"test3") OR title_phrase:"test1 test2 test3"')
        end
      end

      context 'journaltitle' do
        let(:search_field) { 'journaltitle' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('((+title:test1 +title:test2 +title:test3) OR title_phrase:"test1 test2 test3") AND format:Journal/Periodical')
        end
      end

      context 'title_starts' do
        let(:search_field) { 'title_starts' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('title_starts:"test1 test2 test3"')
        end
      end

      context 'lc_callnum' do
        let(:search_field) { 'lc_callnum' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('lc_callnum:"test1 test2 test3"')
        end
      end

      context 'publisher' do
        let(:search_field) { 'publisher' }

        # TODO: Why not '... OR SEARCH_FIELD_phrase:"query"'?
        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('(+publisher:"test1" +publisher:"test2" +publisher:"test3") OR publisher:"test1 test2 test3"')
        end
      end

      context 'author' do
        let(:search_field) { 'author' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('(+author:"test1" +author:"test2" +author:"test3") OR author:"test1 test2 test3"')
        end
      end

      context 'subject' do
        let(:search_field) { 'subject' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('(+subject:"test1" +subject:"test2" +subject:"test3") OR subject:"test1 test2 test3"')
        end
      end

      context 'query contains quotation marks' do
        context 'single quoted query string' do
          let(:q) { '"test1 test2 test3"' }

          context 'all_fields' do
            let(:search_field) { 'all_fields' }

            it 'transforms expected solr params' do
              search_builder.advsearch(solr_params)
              expect(solr_params[:q]).to eq('quoted:"test1 test2 test3"')
            end
          end

          context 'title' do
            let(:search_field) { 'title' }

            it 'transforms expected solr params' do
              search_builder.advsearch(solr_params)
              expect(solr_params[:q]).to eq('title_quoted:"test1 test2 test3"')
            end
          end

          context 'journaltitle' do
            let(:search_field) { 'journaltitle' }

            it 'transforms expected solr params' do
              search_builder.advsearch(solr_params)
              expect(solr_params[:q]).to eq('title_quoted:"test1 test2 test3" AND format:Journal/Periodical')
            end
          end

          context 'title_starts' do
            let(:search_field) { 'title_starts' }

            it 'transforms expected solr params' do
              search_builder.advsearch(solr_params)
              expect(solr_params[:q]).to eq('title_starts:"test1 test2 test3"')
            end
          end

          context 'lc_callnum' do
            let(:search_field) { 'lc_callnum' }

            it 'transforms expected solr params' do
              search_builder.advsearch(solr_params)
              expect(solr_params[:q]).to eq('lc_callnum:"test1 test2 test3"')
            end
          end

          context 'publisher' do
            let(:search_field) { 'publisher' }

            it 'transforms expected solr params' do
              search_builder.advsearch(solr_params)
              expect(solr_params[:q]).to eq('publisher_quoted:"test1 test2 test3"')
            end
          end

          context 'author' do
            let(:search_field) { 'author' }

            it 'transforms expected solr params' do
              search_builder.advsearch(solr_params)
              expect(solr_params[:q]).to eq('author_quoted:"test1 test2 test3"')
            end
          end

          context 'subject' do
            let(:search_field) { 'subject' }

            it 'transforms expected solr params' do
              search_builder.advsearch(solr_params)
              expect(solr_params[:q]).to eq('subject_quoted:"test1 test2 test3"')
            end
          end
        end
      end

      context 'query with mixed quotes' do
        let(:q) { '"test1 test2 test3" test4' }

        context 'all_fields' do
          let(:search_field) { 'all_fields' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(+quoted:"test1 test2 test3" +test4)')
          end
        end

        context 'title' do
          let(:search_field) { 'title' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(+title_quoted:"test1 test2 test3" +title:test4)')
          end
        end

        context 'journaltitle' do
          let(:search_field) { 'journaltitle' }

          # TODO: Why is this not: '(+title_quoted:"test1 test2 test3" +title:test4) AND format:Journal/Periodical'
          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((+title:"test1 +title:test2 +title:test3" +title:test4) OR title_phrase:""test1 test2 test3" test4") AND format:Journal/Periodical')
          end
        end

        context 'title_starts' do
          let(:search_field) { 'title_starts' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('title_starts:"test1 test2 test3 test4"')
          end
        end

        context 'lc_callnum' do
          let(:search_field) { 'lc_callnum' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('lc_callnum:"test1 test2 test3 test4"')
          end
        end

        context 'publisher' do
          let(:search_field) { 'publisher' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(+publisher_quoted:"test1 test2 test3" +publisher:test4)')
          end
        end

        context 'author' do
          let(:search_field) { 'author' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(+author_quoted:"test1 test2 test3" +author:test4)')
          end
        end

        context 'subject' do
          let(:search_field) { 'subject' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(+subject_quoted:"test1 test2 test3" +subject:test4)')
          end
        end
      end
    end

    context 'advanced search' do
      let(:blacklight_params) { {
        q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
        op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
        search_field_row: Array.new(7) { search_field },
        boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"},
        sort: 'score desc, pub_date_sort desc, title_sort asc',
        search_field: 'advanced',
        advanced_query: 'yes'
      } }
      let(:solr_params) { { sort: 'score desc, pub_date_sort desc, title_sort asc' } }

      context 'search_field_row with all_fields' do
        let(:search_field) { 'all_fields' }

        # TODO: Extra space at end of starts query? (starts:"test 7 test8 ")
        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+"test1" +"test2" ) OR (phrase:"test1 test2"))' +
                                        ' AND quoted:"test3 test4") ' +
                                        ' AND (test5 OR test6))' +
                                        ' AND starts:"test7 test8 ")' +
                                        ' AND quoted:"test9 test10")' +
                                        ' OR ((+"test11" +"test12" ) OR (phrase:"test11 test12")))' +
                                        ' -((+"test13" +"test14" ) OR (phrase:"test13 test14")))')
        end
      end

      context 'search_field_row with title' do
        let(:search_field) { 'title' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+title:"test1" +title:"test2" ) OR (title_phrase:"test1 test2"))' +
                                        ' AND title_quoted:"test3 test4") ' +
                                        ' AND (title:test5 OR title:test6))' +
                                        ' AND title_starts:"test7 test8 ")' +
                                        ' AND (title_quoted:"test9 test10"))' +
                                        ' OR ((+title:"test11" +title:"test12" ) OR (title_phrase:"test11 test12")))' +
                                        ' -((+title:"test13" +title:"test14" ) OR (title_phrase:"test13 test14")))')
        end
      end

      context 'search_field_row with journaltitle' do
        let(:search_field) { 'journaltitle' }

        # TODO: Why does this one use journaltitle_quoted but journaltitle catalog search with quotation marks does not?
        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( ((((+title:"test1" +title:"test2" ) OR (title:"test1 test2")) AND format:Journal/Periodical )' +
                                        ' AND journaltitle_quoted:"test3 test4") ' +
                                        ' AND ((title:test5 OR title:test6) AND format:Journal/Periodical ))' +
                                        ' AND (title_starts:"test7 test8 " AND format:Journal/Periodical ))' +
                                        ' AND (journaltitle_quoted:"test9 test10"))' +
                                        ' OR (((+title:"test11" +title:"test12" ) OR (title:"test11 test12")) AND format:Journal/Periodical ))' +
                                        ' -(((+title:"test13" +title:"test14" ) OR (title:"test13 test14")) AND format:Journal/Periodical ))')
        end
      end

      context 'search_field_row with author' do
        let(:search_field) { 'author' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+author:"test1" +author:"test2" ) OR (author:"test1 test2"))' +
                                        ' AND author_quoted:"test3 test4") ' +
                                        ' AND (author:test5 OR author:test6))' +
                                        ' AND author_starts:"test7 test8 ")' +
                                        ' AND (author_quoted:"test9 test10"))' +
                                        ' OR ((+author:"test11" +author:"test12" ) OR (author:"test11 test12")))' +
                                        ' -((+author:"test13" +author:"test14" ) OR (author:"test13 test14")))')
        end
      end

      context 'search_field_row with subject' do
        let(:search_field) { 'subject' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+subject:"test1" +subject:"test2" ) OR (subject:"test1 test2"))' +
                                        ' AND subject_quoted:"test3 test4") ' +
                                        ' AND (subject:test5 OR subject:test6))' +
                                        ' AND subject_starts:"test7 test8 ")' +
                                        ' AND (subject_quoted:"test9 test10"))' +
                                        ' OR ((+subject:"test11" +subject:"test12" ) OR (subject:"test11 test12")))' +
                                        ' -((+subject:"test13" +subject:"test14" ) OR (subject:"test13 test14")))')
        end
      end

      context 'search_field_row with lc_callnum' do
        let(:search_field) { 'lc_callnum' }

        # TODO: Should lc_callnum be querying "quoted" for phrase searches?
        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (lc_callnum:"test1 test2"' +
                                        ' AND lc_callnum_quoted:"test3 test4") ' +
                                        ' AND lc_callnum:"test5 test6")' +
                                        ' AND lc_callnum_starts:"test7 test8")' +
                                        ' AND quoted:"test9 test10")' +
                                        ' OR lc_callnum:"test11 test12")' +
                                        ' -lc_callnum:"test13 test14")')
        end
      end

      context 'search_field_row with series' do
        let(:search_field) { 'series' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+series:"test1" +series:"test2" ) OR (series:"test1 test2"))' +
                                        ' AND series_quoted:"test3 test4") ' +
                                        ' AND (series:test5 OR series:test6))' +
                                        ' AND series_starts:"test7 test8 ")' +
                                        ' AND (series_quoted:"test9 test10"))' +
                                        ' OR ((+series:"test11" +series:"test12" ) OR (series:"test11 test12")))' +
                                        ' -((+series:"test13" +series:"test14" ) OR (series:"test13 test14")))')
        end
      end

      context 'search_field_row with publisher' do
        let(:search_field) { 'publisher' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+publisher:"test1" +publisher:"test2" ) OR (publisher:"test1 test2"))' +
                                        ' AND publisher_quoted:"test3 test4") ' +
                                        ' AND (publisher:test5 OR publisher:test6))' +
                                        ' AND publisher_starts:"test7 test8 ")' +
                                        ' AND (publisher_quoted:"test9 test10"))' +
                                        ' OR ((+publisher:"test11" +publisher:"test12" ) OR (publisher:"test11 test12")))' +
                                        ' -((+publisher:"test13" +publisher:"test14" ) OR (publisher:"test13 test14")))')
        end
      end

      context 'search_field_row with pubplace' do
        let(:search_field) { 'pubplace' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+pubplace:"test1" +pubplace:"test2" ) OR (pubplace:"test1 test2"))' +
                                        ' AND pubplace_quoted:"test3 test4") ' +
                                        ' AND (pubplace:test5 OR pubplace:test6))' +
                                        ' AND pubplace_starts:"test7 test8 ")' +
                                        ' AND (pubplace_quoted:"test9 test10"))' +
                                        ' OR ((+pubplace:"test11" +pubplace:"test12" ) OR (pubplace:"test11 test12")))' +
                                        ' -((+pubplace:"test13" +pubplace:"test14" ) OR (pubplace:"test13 test14")))')
        end
      end

      context 'search_field_row with number' do
        let(:search_field) { 'number' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+number:"test1" +number:"test2" ) OR (number_phrase:"test1 test2"))' +
                                        ' AND number_quoted:"test3 test4") ' +
                                        ' AND (number:test5 OR number:test6))' +
                                        ' AND number_starts:"test7 test8 ")' +
                                        ' AND (number_quoted:"test9 test10"))' +
                                        ' OR ((+number:"test11" +number:"test12" ) OR (number_phrase:"test11 test12")))' +
                                        ' -((+number:"test13" +number:"test14" ) OR (number_phrase:"test13 test14")))')
        end
      end

      context 'search_field_row with isbnissn' do
        let(:search_field) { 'isbnissn' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+isbnissn:"test1" +isbnissn:"test2" ) OR (isbnissn:"test1 test2"))' +
                                        ' AND isbnissn_quoted:"test3 test4") ' +
                                        ' AND (isbnissn:test5 OR isbnissn:test6))' +
                                        ' AND isbnissn_starts:"test7 test8 ")' +
                                        ' AND (isbnissn_quoted:"test9 test10"))' +
                                        ' OR ((+isbnissn:"test11" +isbnissn:"test12" ) OR (isbnissn:"test11 test12")))' +
                                        ' -((+isbnissn:"test13" +isbnissn:"test14" ) OR (isbnissn:"test13 test14")))')
        end
      end

      context 'search_field_row with notes' do
        let(:search_field) { 'notes' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+notes:"test1" +notes:"test2" ) OR (notes:"test1 test2"))' +
                                        ' AND notes_quoted:"test3 test4") ' +
                                        ' AND (notes:test5 OR notes:test6))' +
                                        ' AND notes_starts:"test7 test8 ")' +
                                        ' AND (notes_quoted:"test9 test10"))' +
                                        ' OR ((+notes:"test11" +notes:"test12" ) OR (notes:"test11 test12")))' +
                                        ' -((+notes:"test13" +notes:"test14" ) OR (notes:"test13 test14")))')
        end
      end

      context 'search_field_row with donor' do
        let(:search_field) { 'donor' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('( ( ( ( ( (((+donor:"test1" +donor:"test2" ) OR (donor:"test1 test2"))' +
                                        ' AND donor_quoted:"test3 test4") ' +
                                        ' AND (donor:test5 OR donor:test6))' +
                                        ' AND donor_starts:"test7 test8 ")' +
                                        ' AND (donor_quoted:"test9 test10"))' +
                                        ' OR ((+donor:"test11" +donor:"test12" ) OR (donor:"test11 test12")))' +
                                        ' -((+donor:"test13" +donor:"test14" ) OR (donor:"test13 test14")))')
        end
      end
    end
  end
end
