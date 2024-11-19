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

  # TODO: Test for words with hyphens and apostrophes, with and without quoted terms
  # TODO: Review the commented out expects with others
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

        context '1 search term' do
          let(:q) { 'test'}

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('("test") OR phrase:"test"')
            # expect(solr_params[:q]).to eq('"test" OR phrase:"test"')
          end
        end

        context 'multiple search terms' do
          let(:q) { 'test1 test2 test3'}

          # TODO: Does this not actually work the way that we'd expect? Is AND treated like OR here without extra parentheses?
          #       https://culibrary.atlassian.net/browse/DACCESS-359
          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('("test1" AND "test2"  AND "test3") OR phrase:"test1 test2 test3"')
            # expect(solr_params[:q]).to eq('("test1" AND "test2" AND "test3") OR phrase:"test1 test2 test3"')
          end
        end
      end

      context 'title' do
        let(:search_field) { 'title' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('(+title:"test1" +title:"test2" +title:"test3") OR title_phrase:"test1 test2 test3"')
          # expect(solr_params[:q]).to eq('(title:"test1" AND title:"test2" AND title:"test3") OR title_phrase:"test1 test2 test3"')
        end
      end

      context 'journaltitle' do
        let(:search_field) { 'journaltitle' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('((+title:test1 +title:test2 +title:test3) OR title_phrase:"test1 test2 test3") AND format:Journal/Periodical')
          # expect(solr_params[:q]).to eq('((title:"test1" AND title:"test2" AND title:"test3") OR title_phrase:"test1 test2 test3") AND format:Journal/Periodical')
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
          expect(solr_params[:q]).to eq('(+publisher:"test1" +publisher:"test2" +publisher:"test3") OR publisher:"test1 test2 test3"')
          # expect(solr_params[:q]).to eq('(publisher:"test1" AND publisher:"test2" AND publisher:"test3") OR publisher:"test1 test2 test3"')
        end
      end

      context 'author' do
        let(:search_field) { 'author' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('(+author:"test1" +author:"test2" +author:"test3") OR author:"test1 test2 test3"')
          # expect(solr_params[:q]).to eq('(author:"test1" AND author:"test2" AND author:"test3") OR author:"test1 test2 test3"')
        end
      end

      context 'subject' do
        let(:search_field) { 'subject' }

        it 'transforms expected solr params' do
          search_builder.advsearch(solr_params)
          expect(solr_params[:q]).to eq('(+subject:"test1" +subject:"test2" +subject:"test3") OR subject:"test1 test2 test3"')
          # expect(solr_params[:q]).to eq('(subject:"test1" AND subject:"test2" AND subject:"test3") OR subject:"test1 test2 test3"')
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

          # TODO: CHECK THIS one, esp the latter part
          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(+quoted:"test1 test2 test3" +test4)')
            # expect(solr_params[:q]).to eq('quoted:"test1 test2 test3" AND ("test4" OR phrase:"test4")')
          end
        end

        context 'title' do
          let(:search_field) { 'title' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(+title_quoted:"test1 test2 test3" +title:test4)')
            # expect(solr_params[:q]).to eq('title_quoted:"test1 test2 test3" AND (title:"test4" OR title_phrase:"test4"')
          end
        end

        context 'journaltitle' do
          let(:search_field) { 'journaltitle' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((+title:"test1 +title:test2 +title:test3" +title:test4) OR title_phrase:""test1 test2 test3" test4") AND format:Journal/Periodical')
            # expect(solr_params[:q]).to eq('title_quoted:"test1 test2 test3" AND (title:"test4" OR title_phrase:"test4") AND format:Journal/Periodical')
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
            # expect(solr_params[:q]).to eq('publisher_quoted:"test1 test2 test3" AND publisher:"test4"')
          end

          # TODO: Fix the org of these tests
          # TODO: Also check this one
          context 'query with mixed quotes and multiword non-quoted terms' do
            let(:q) { '"test1 test2 test3" test4 test5' }


            it 'transforms expected solr params' do
              search_builder.advsearch(solr_params)
              expect(solr_params[:q]).to eq('(+publisher_quoted:"test1 test2 test3" +publisher:test4 +publisher:test5)')
              # expect(solr_params[:q]).to eq('publisher_quoted:"test1 test2 test3" AND ((publisher:"test4" AND publisher:"test5") OR publisher:"test4 test5")')
            end
          end
        end

        context 'author' do
          let(:search_field) { 'author' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(+author_quoted:"test1 test2 test3" +author:test4)')
            # expect(solr_params[:q]).to eq('author_quoted:"test1 test2 test3" AND author:"test4"')
          end
        end

        context 'subject' do
          let(:search_field) { 'subject' }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(+subject_quoted:"test1 test2 test3" +subject:test4)')
            # expect(solr_params[:q]).to eq('(subject_quoted:"test1 test2 test3" AND subject:"test4")')
          end
        end
      end
    end

    context 'advanced search' do
      let(:blacklight_params) { user_params.merge({
        sort: 'score desc, pub_date_sort desc, title_sort asc',
        search_field: 'advanced',
        advanced_query: 'yes'
      }) }
      let(:solr_params) { { sort: 'score desc, pub_date_sort desc, title_sort asc' } }

      context 'search_field_row with all_fields' do
        let(:search_field) { 'all_fields' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( +test )')
            # expect(solr_params[:q]).to eq('"test" OR phrase:"test"')
          end
        end

        context 'query ALL search terms' do
          let(:user_params) { {
            q_row: ['test1 test2'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+"test1" +"test2" ) OR (phrase:"test1 test2")) )')
            # expect(solr_params[:q]).to eq('("test1" AND "test2") OR phrase:"test1 test2"')
          end
        end

        context 'query ANY search term' do
          let(:user_params) { {
            q_row: ['test1 test2'],
            op_row: ['OR'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          # TODO: Check on this one. Do we not use phrase for op_row OR?
          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( (test1 OR test2) )')
            # expect(solr_params[:q]).to eq('"test1" OR "test2"')
          end
        end

        context 'query for search terms as PHRASE' do
          let(:user_params) { {
            q_row: ['test1 test2'],
            op_row: ['phrase'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( quoted:"test1 test2" )')
            # expect(solr_params[:q]).to eq('quoted:"test1 test2"')
          end
        end

        context 'query for search field that BEGINS WITH search terms' do
          let(:user_params) { {
            q_row: ['test1 test2'],
            op_row: ['begins_with'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( starts:"test1 test2 " )')
            # expect(solr_params[:q]).to eq('starts:"test1 test2"')
          end
        end

        context 'query 1 AND query 2' do
          let(:user_params) { {
            q_row: ['pickle cheese', 'dill'],
            op_row: ['AND', 'AND'],
            search_field_row: [search_field, search_field],
            boolean_row: {"1": "AND"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(((+"pickle" +"cheese" ) OR (phrase:"pickle cheese")) AND +dill) ')
            # expect(solr_params[:q]).to eq('(("pickle" AND "cheese") OR phrase:"pickle cheese") AND ("dill" OR phrase:"dill")')
          end
        end

        context 'query 1 OR query 2' do
          let(:user_params) { {
            q_row: ['pickle cheese', 'dill'],
            op_row: ['AND', 'AND'],
            search_field_row: [search_field, search_field],
            boolean_row: {"1": "OR"}
          } }

          # TODO: If search term is 1 word (e.g. dill), it doesn't make sense to combine OR with +
          #       https://culibrary.atlassian.net/browse/DACCESS-354
          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(((+"pickle" +"cheese" ) OR (phrase:"pickle cheese")) OR +dill) ')
            # expect(solr_params[:q]).to eq('(("pickle" AND "cheese") OR phrase:"pickle cheese") OR ("dill" OR phrase:"dill")')
          end
        end

        context 'query 1 NOT query 2' do
          let(:user_params) { {
            q_row: ['pickle cheese', 'dill'],
            op_row: ['AND', 'AND'],
            search_field_row: [search_field, search_field],
            boolean_row: {"1": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(((+"pickle" +"cheese" ) OR (phrase:"pickle cheese")) -dill) ')
            # expect(solr_params[:q]).to eq('(("pickle" AND "cheese") OR phrase:"pickle cheese") NOT ("dill" OR phrase:"dill")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+"test1" +"test2" ) OR (phrase:"test1 test2"))' +
                                          ' AND quoted:"test3 test4") ' +
                                          ' AND (test5 OR test6))' +
                                          ' AND starts:"test7 test8 ")' +
                                          ' AND quoted:"test9 test10")' +
                                          ' OR ((+"test11" +"test12" ) OR (phrase:"test11 test12")))' +
                                          ' -((+"test13" +"test14" ) OR (phrase:"test13 test14")))')
            # expect(solr_params[:q]).to eq('(((((((("test1" AND "test2") OR phrase:"test1 test2")' +
            #                               ' AND quoted:"test3 test4") ' +
            #                               ' AND ("test5" OR "test6"))' +
            #                               ' AND starts:"test7 test8")' +
            #                               ' AND quoted:"test9 test10")' +
            #                               ' OR (("test11" AND "test12") OR phrase:"test11 test12"))' +
            #                               ' NOT (("test13" AND "test14" ) OR phrase:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with title' do
        let(:search_field) { 'title' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+title:"test") OR title_phrase:"test") )')
            # expect(solr_params[:q]).to eq('title:"test" OR title_phrase:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+title:"test1" +title:"test2" ) OR (title_phrase:"test1 test2"))' +
              ' AND title_quoted:"test3 test4") ' +
              ' AND (title:test5 OR title:test6))' +
              ' AND title_starts:"test7 test8 ")' +
              ' AND (title_quoted:"test9 test10"))' +
              ' OR ((+title:"test11" +title:"test12" ) OR (title_phrase:"test11 test12")))' +
              ' -((+title:"test13" +title:"test14" ) OR (title_phrase:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((title:"test1" AND title:"test2") OR title_phrase:"test1 test2")' +
            #   ' AND title_quoted:"test3 test4")' +
            #   ' AND (title:"test5" OR title:"test6"))' +
            #   ' AND title_starts:"test7 test8")' +
            #   ' AND title_quoted:"test9 test10")' +
            #   ' OR ((title:"test11" AND title:"test12") OR title_phrase:"test11 test12"))' +
            #   ' NOT ((title:"test13" AND title:"test14") OR title_phrase:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with journaltitle' do
        let(:search_field) { 'journaltitle' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+title:"test" OR title_phrase:"test") AND format:Journal/Periodical) )')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( ((((+title:"test1" +title:"test2" ) OR (title:"test1 test2")) AND format:Journal/Periodical )' +
                                          ' AND journaltitle_quoted:"test3 test4") ' +
                                          ' AND ((title:test5 OR title:test6) AND format:Journal/Periodical ))' +
                                          ' AND (title_starts:"test7 test8 " AND format:Journal/Periodical ))' +
                                          ' AND (journaltitle_quoted:"test9 test10"))' +
                                          ' OR (((+title:"test11" +title:"test12" ) OR (title:"test11 test12")) AND format:Journal/Periodical ))' +
                                          ' -(((+title:"test13" +title:"test14" ) OR (title:"test13 test14")) AND format:Journal/Periodical ))')
            # expect(solr_params[:q]).to eq('(((((((((title:"test1" AND title:"test2") OR title_phrase:"test1 test2") AND format:Journal/Periodical)' +
            #                               ' AND (title_quoted:"test3 test4" AND format:Journal/Periodical))' +
            #                               ' AND ((title:"test5" OR title:"test6") AND format:Journal/Periodical))' +
            #                               ' AND (title_starts:"test7 test8" AND format:Journal/Periodical))' +
            #                               ' AND (title_quoted:"test9 test10" AND format:Journal/Periodical))' +
            #                               ' OR (((title:"test11" AND title:"test12") OR title_phrase:"test11 test12") AND format:Journal/Periodical))' +
            #                               ' NOT (((title:"test13" AND title:"test14") OR title_phrase:"test13 test14") AND format:Journal/Periodical))')
          end
        end
      end

      context 'search_field_row with author' do
        let(:search_field) { 'author' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+author:"test") OR author:"test") )')
            # expect(solr_params[:q]).to eq('author:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+author:"test1" +author:"test2" ) OR (author:"test1 test2"))' +
                                          ' AND author_quoted:"test3 test4") ' +
                                          ' AND (author:test5 OR author:test6))' +
                                          ' AND author_starts:"test7 test8 ")' +
                                          ' AND (author_quoted:"test9 test10"))' +
                                          ' OR ((+author:"test11" +author:"test12" ) OR (author:"test11 test12")))' +
                                          ' -((+author:"test13" +author:"test14" ) OR (author:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((author:"test1" AND author:"test2") OR author:"test1 test2")' +
            #                               ' AND author_quoted:"test3 test4")' +
            #                               ' AND (author:"test5" OR author:"test6"))' +
            #                               ' AND author_starts:"test7 test8")' +
            #                               ' AND author_quoted:"test9 test10")' +
            #                               ' OR ((author:"test11" AND author:"test12") OR author:"test11 test12"))' +
            #                               ' NOT ((author:"test13" AND author:"test14") OR author:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with subject' do
        let(:search_field) { 'subject' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+subject:"test") OR subject:"test") )')
            # expect(solr_params[:q]).to eq('subject:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+subject:"test1" +subject:"test2" ) OR (subject:"test1 test2"))' +
                                          ' AND subject_quoted:"test3 test4") ' +
                                          ' AND (subject:test5 OR subject:test6))' +
                                          ' AND subject_starts:"test7 test8 ")' +
                                          ' AND (subject_quoted:"test9 test10"))' +
                                          ' OR ((+subject:"test11" +subject:"test12" ) OR (subject:"test11 test12")))' +
                                          ' -((+subject:"test13" +subject:"test14" ) OR (subject:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((subject:"test1" AND subject:"test2") OR (subject:"test1 test2"))' +
            #                               ' AND subject_quoted:"test3 test4")' +
            #                               ' AND (subject:"test5" OR subject:"test6"))' +
            #                               ' AND subject_starts:"test7 test8")' +
            #                               ' AND subject_quoted:"test9 test10")' +
            #                               ' OR ((subject:"test11" AND subject:"test12") OR subject:"test11 test12"))' +
            #                               ' NOT ((subject:"test13" AND subject:"test14") OR subject:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with lc_callnum' do
        let(:search_field) { 'lc_callnum' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( lc_callnum:"test" )')
            # expect(solr_params[:q]).to eq('lc_callnum:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (lc_callnum:"test1 test2"' +
                                          ' AND lc_callnum_quoted:"test3 test4") ' +
                                          ' AND lc_callnum:"test5 test6")' +
                                          ' AND lc_callnum_starts:"test7 test8")' +
                                          ' AND quoted:"test9 test10")' +
                                          ' OR lc_callnum:"test11 test12")' +
                                          ' -lc_callnum:"test13 test14")')
            # expect(solr_params[:q]).to eq('((((((lc_callnum:"test1 test2"' +
            #                               ' AND lc_callnum:"test3 test4") ' +
            #                               ' AND lc_callnum:"test5 test6")' +
            #                               ' AND lc_callnum_starts:"test7 test8")' +
            #                               ' AND lc_callnum:"test9 test10")' +
            #                               ' OR lc_callnum:"test11 test12")' +
            #                               ' NOT lc_callnum:"test13 test14")')
          end
        end
      end

      context 'search_field_row with series' do
        let(:search_field) { 'series' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+series:"test") OR series:"test") )')
            # expect(solr_params[:q]).to eq('series:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+series:"test1" +series:"test2" ) OR (series:"test1 test2"))' +
                                          ' AND series_quoted:"test3 test4") ' +
                                          ' AND (series:test5 OR series:test6))' +
                                          ' AND series_starts:"test7 test8 ")' +
                                          ' AND (series_quoted:"test9 test10"))' +
                                          ' OR ((+series:"test11" +series:"test12" ) OR (series:"test11 test12")))' +
                                          ' -((+series:"test13" +series:"test14" ) OR (series:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((series:"test1" AND series:"test2" ) OR series:"test1 test2")' +
            #                               ' AND series_quoted:"test3 test4")' +
            #                               ' AND (series:"test5" OR series:"test6"))' +
            #                               ' AND series_starts:"test7 test8")' +
            #                               ' AND series_quoted:"test9 test10")' +
            #                               ' OR ((series:"test11" AND series:"test12") OR series:"test11 test12"))' +
            #                               ' NOT ((series:"test13" AND series:"test14") OR series:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with publisher' do
        let(:search_field) { 'publisher' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+publisher:"test") OR publisher:"test") )')
            # expect(solr_params[:q]).to eq('publisher:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+publisher:"test1" +publisher:"test2" ) OR (publisher:"test1 test2"))' +
                                          ' AND publisher_quoted:"test3 test4") ' +
                                          ' AND (publisher:test5 OR publisher:test6))' +
                                          ' AND publisher_starts:"test7 test8 ")' +
                                          ' AND (publisher_quoted:"test9 test10"))' +
                                          ' OR ((+publisher:"test11" +publisher:"test12" ) OR (publisher:"test11 test12")))' +
                                          ' -((+publisher:"test13" +publisher:"test14" ) OR (publisher:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((publisher:"test1" AND publisher:"test2") OR publisher:"test1 test2")' +
            #                               ' AND publisher_quoted:"test3 test4") ' +
            #                               ' AND (publisher:"test5" OR publisher:"test6"))' +
            #                               ' AND publisher_starts:"test7 test8")' +
            #                               ' AND publisher_quoted:"test9 test10")' +
            #                               ' OR ((publisher:"test11" AND publisher:"test12") OR publisher:"test11 test12"))' +
            #                               ' NOT ((publisher:"test13" AND publisher:"test14") OR publisher:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with pubplace' do
        let(:search_field) { 'pubplace' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+pubplace:"test") OR pubplace:"test") )')
            # expect(solr_params[:q]).to eq('pubplace:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+pubplace:"test1" +pubplace:"test2" ) OR (pubplace:"test1 test2"))' +
                                          ' AND pubplace_quoted:"test3 test4") ' +
                                          ' AND (pubplace:test5 OR pubplace:test6))' +
                                          ' AND pubplace_starts:"test7 test8 ")' +
                                          ' AND (pubplace_quoted:"test9 test10"))' +
                                          ' OR ((+pubplace:"test11" +pubplace:"test12" ) OR (pubplace:"test11 test12")))' +
                                          ' -((+pubplace:"test13" +pubplace:"test14" ) OR (pubplace:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((pubplace:"test1" AND pubplace:"test2") OR pubplace:"test1 test2")' +
            #                               ' AND pubplace_quoted:"test3 test4")' +
            #                               ' AND (pubplace:"test5" OR pubplace:"test6"))' +
            #                               ' AND pubplace_starts:"test7 test8")' +
            #                               ' AND pubplace_quoted:"test9 test10")' +
            #                               ' OR ((pubplace:"test11" AND pubplace:"test12") OR pubplace:"test11 test12"))' +
            #                               ' NOT ((pubplace:"test13" AND pubplace:"test14") OR pubplace:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with number' do
        let(:search_field) { 'number' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+number:"test") OR number_phrase:"test") )')
            # expect(solr_params[:q]).to eq('number:"test" OR number_phrase:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+number:"test1" +number:"test2" ) OR (number_phrase:"test1 test2"))' +
                                          ' AND number_quoted:"test3 test4") ' +
                                          ' AND (number:test5 OR number:test6))' +
                                          ' AND number_starts:"test7 test8 ")' +
                                          ' AND (number_quoted:"test9 test10"))' +
                                          ' OR ((+number:"test11" +number:"test12" ) OR (number_phrase:"test11 test12")))' +
                                          ' -((+number:"test13" +number:"test14" ) OR (number_phrase:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((number:"test1" AND number:"test2") OR number_phrase:"test1 test2")' +
            #                               ' AND number_quoted:"test3 test4")' +
            #                               ' AND (number:"test5" OR number:"test6"))' +
            #                               ' AND number_starts:"test7 test8")' +
            #                               ' AND number_quoted:"test9 test10")' +
            #                               ' OR ((number:"test11" AND number:"test12") OR number_phrase:"test11 test12"))' +
            #                               ' NOT ((number:"test13" AND number:"test14") OR number_phrase:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with isbnissn' do
        let(:search_field) { 'isbnissn' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+isbnissn:"test") OR isbnissn:"test") )')
            # expect(solr_params[:q]).to eq('isbnissn:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+isbnissn:"test1" +isbnissn:"test2" ) OR (isbnissn:"test1 test2"))' +
                                          ' AND isbnissn_quoted:"test3 test4") ' +
                                          ' AND (isbnissn:test5 OR isbnissn:test6))' +
                                          ' AND isbnissn_starts:"test7 test8 ")' +
                                          ' AND (isbnissn_quoted:"test9 test10"))' +
                                          ' OR ((+isbnissn:"test11" +isbnissn:"test12" ) OR (isbnissn:"test11 test12")))' +
                                          ' -((+isbnissn:"test13" +isbnissn:"test14" ) OR (isbnissn:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((isbnissn:"test1" AND isbnissn:"test2") OR isbnissn:"test1 test2")' +
            #                               ' AND isbnissn_quoted:"test3 test4")' +
            #                               ' AND (isbnissn:"test5" OR isbnissn:"test6"))' +
            #                               ' AND isbnissn_starts:"test7 test8")' +
            #                               ' AND isbnissn_quoted:"test9 test10")' +
            #                               ' OR ((isbnissn:"test11" AND isbnissn:"test12") OR isbnissn:"test11 test12"))' +
            #                               ' NOT ((isbnissn:"test13" AND isbnissn:"test14") OR isbnissn:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with notes' do
        let(:search_field) { 'notes' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+notes:"test") OR notes:"test") )')
            # expect(solr_params[:q]).to eq('notes:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+notes:"test1" +notes:"test2" ) OR (notes:"test1 test2"))' +
                                          ' AND notes_quoted:"test3 test4") ' +
                                          ' AND (notes:test5 OR notes:test6))' +
                                          ' AND notes_starts:"test7 test8 ")' +
                                          ' AND (notes_quoted:"test9 test10"))' +
                                          ' OR ((+notes:"test11" +notes:"test12" ) OR (notes:"test11 test12")))' +
                                          ' -((+notes:"test13" +notes:"test14" ) OR (notes:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((notes:"test1" AND notes:"test2") OR notes:"test1 test2")' +
            #                               ' AND notes_quoted:"test3 test4")' +
            #                               ' AND (notes:"test5" OR notes:"test6"))' +
            #                               ' AND notes_starts:"test7 test8")' +
            #                               ' AND notes_quoted:"test9 test10")' +
            #                               ' OR ((notes:"test11" AND notes:"test12") OR notes:"test11 test12"))' +
            #                               ' NOT ((notes:"test13" AND notes:"test14") OR notes:"test13 test14"))')
          end
        end
      end

      context 'search_field_row with donor' do
        let(:search_field) { 'donor' }

        context 'simplest query' do
          let(:user_params) { {
            q_row: ['test'],
            op_row: ['AND'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ((+donor:"test") OR donor:"test") )')
            # expect(solr_params[:q]).to eq('donor:"test"')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1": "AND", "2": "AND", "3": "AND", "4": "AND", "5": "OR", "6": "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('( ( ( ( ( (((+donor:"test1" +donor:"test2" ) OR (donor:"test1 test2"))' +
                                          ' AND donor_quoted:"test3 test4") ' +
                                          ' AND (donor:test5 OR donor:test6))' +
                                          ' AND donor_starts:"test7 test8 ")' +
                                          ' AND (donor_quoted:"test9 test10"))' +
                                          ' OR ((+donor:"test11" +donor:"test12" ) OR (donor:"test11 test12")))' +
                                          ' -((+donor:"test13" +donor:"test14" ) OR (donor:"test13 test14")))')
            # expect(solr_params[:q]).to eq('((((((((donor:"test1" AND donor:"test2") OR donor:"test1 test2")' +
            #                               ' AND donor_quoted:"test3 test4")' +
            #                               ' AND (donor:"test5" OR donor:"test6"))' +
            #                               ' AND donor_starts:"test7 test8")' +
            #                               ' AND donor_quoted:"test9 test10")' +
            #                               ' OR ((donor:"test11" AND donor:"test12") OR donor:"test11 test12"))' +
            #                               ' NOT ((donor:"test13" AND donor:"test14") OR donor:"test13 test14"))')
          end
        end
      end
    end
  end
end
