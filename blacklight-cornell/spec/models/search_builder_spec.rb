require 'rails_helper'

RSpec.describe SearchBuilder, type: :model do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:scope) { double blacklight_config: blacklight_config }
  let(:advanced_search_fields) { %w[all_fields title journaltitle author subject lc_callnum series publisher pubplace number isbnissn notes donor] }
  subject(:search_builder) { described_class.new scope }

  describe '#group_bools' do
    let(:params) {
      {
        q_row: ['curly', 'moe', 'larry', 'rando'],
        boolean_row: ['AND', 'OR', 'NOT']
      }
    }

    context 'single word queries' do
      it 'returns queries chained by expected booleans' do
        params = {
          q_row: ['curly', 'moe', 'larry', 'rando'],
          boolean_row: ['AND', 'OR', 'NOT']
        }
        expect(search_builder.group_bools(params)).to eq('((((curly) AND (moe)) OR (larry)) NOT (rando))')
      end
    end

    context 'complex queries' do
      it 'returns queries chained by expected booleans' do
        params = {
          q_row: ['(title:"curly" AND title:"howard") OR title_phrase:"curly howard',
                  '(author:"moe" AND author:"howard") OR author_phrase:"moe howard"',
                  'subject:"larry" OR subject:"fine"'],
          boolean_row: ['AND', 'OR']
        }
        expect(search_builder.group_bools(params)).
          to eq('((((title:"curly" AND title:"howard") OR title_phrase:"curly howard) AND ' \
                '((author:"moe" AND author:"howard") OR author_phrase:"moe howard")) OR ' \
                '(subject:"larry" OR subject:"fine"))')
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

  describe '#remove_blank_rows' do
    context 'single row query' do
      context 'query is not blank' do
        it 'removes last blank row' do
          params = search_builder.remove_blank_rows({ q_row: ['test', ''],
                                                      op_row: ['AND', 'AND'],
                                                      search_field_row: ['all_fields', 'all_fields'],
                                                      boolean_row: { '1' => 'AND' } })
          expect(params).to eq({ q_row: ['test'], op_row: ['AND'], search_field_row: ['all_fields'], boolean_row: [] })
        end
      end

      context 'query is blank' do
        it 'removes blank rows' do
          params = search_builder.remove_blank_rows({ q_row: ['', ''],
                                                      op_row: ['AND', 'AND'],
                                                      search_field_row: ['all_fields', 'all_fields'],
                                                      boolean_row: { '1' => 'AND' } })
          expect(params).to eq({ q_row: [], op_row: [], search_field_row: [], boolean_row: [] })
        end
      end
    end

    context 'multiple row query' do
      context 'query is not blank' do
        it 'returns expected params' do
          params = search_builder.remove_blank_rows({ q_row: ['pickles', 'cheese', 'toast'],
                                                      op_row: ['AND', 'AND', 'begins_with'],
                                                      search_field_row: ['title', 'all_fields', 'notes'],
                                                      boolean_row: { '1' => 'OR', '2' => 'AND' } })
          expect(params).to eq({ q_row: ['pickles', 'cheese', 'toast'],
                                 op_row: ['AND', 'AND', 'begins_with'],
                                 search_field_row: ['title', 'all_fields', 'notes'],
                                 boolean_row: ['OR', 'AND'] })
        end
      end
      
      context 'middle query is blank' do
        it 'removes blank row' do
          params = search_builder.remove_blank_rows({ q_row: ['pickles', '', 'toast'],
                                                      op_row: ['AND', 'AND', 'begins_with'],
                                                      search_field_row: ['title', 'all_fields', 'notes'],
                                                      boolean_row: { '1' => 'OR', '2' => 'AND' } })
          expect(params).to eq({ q_row: ['pickles', 'toast'],
                                 op_row: ['AND', 'begins_with'],
                                 search_field_row: ['title', 'notes'],
                                 boolean_row: ['AND'] })
        end

        it 'removes blank rows' do
          params = search_builder.remove_blank_rows({ q_row: ['pickles', '', '', 'sandwich'],
                                                      op_row: ['AND', 'AND', 'begins_with', 'OR'],
                                                      search_field_row: ['title', 'all_fields', 'notes', 'subject'],
                                                      boolean_row: { '1' => 'OR', '2' => 'AND', '3' => 'NOT' } })
          expect(params).to eq({ q_row: ['pickles', 'sandwich'],
                                 op_row: ['AND', 'OR'],
                                 search_field_row: ['title', 'subject'],
                                 boolean_row: ['NOT'] })
        end
      end

      context 'first query is blank' do
        it 'removes blank rows' do
          params = search_builder.remove_blank_rows({ q_row: ['', 'cheese', 'toast'],
                                                      op_row: ['AND', 'AND', 'begins_with'],
                                                      search_field_row: ['title', 'all_fields', 'notes'],
                                                      boolean_row: { '1' => 'OR', '2' => 'AND' } })
          expect(params).to eq({ q_row: ['cheese', 'toast'],
                                 op_row: ['AND', 'begins_with'],
                                 search_field_row: ['all_fields', 'notes'],
                                 boolean_row: ['AND'] })
        end
      end
    end

    context "row counts don't match" do
      context 'q_row count is less than boolean, op, or search_field row counts' do
        it 'removes extra boolean, op, or search_field rows' do
          params = search_builder.remove_blank_rows({ q_row: ['pickles', 'cheese'],
                                                      op_row: ['AND', 'AND', 'begins_with'],
                                                      search_field_row: ['title', 'all_fields', 'notes'],
                                                      boolean_row: { '1' => 'OR', '2' => 'AND' } })
          expect(params).to eq({ q_row: ['pickles', 'cheese'],
          op_row: ['AND', 'AND'],
          search_field_row: ['title', 'all_fields'],
          boolean_row: ['OR'] })
        end
      end

      context 'q_row_count is more than boolean, op, or search_field row counts' do
        it 'returns params with default booleans, ops, or search_fields when missing' do
          params = search_builder.remove_blank_rows({ q_row: ['pickles', 'cheese', 'toast'],
                                                      op_row: ['AND', 'begins_with'],
                                                      search_field_row: ['title', 'notes'],
                                                      boolean_row: { '1' => 'OR' } })
          expect(params).to eq({ q_row: ['pickles', 'cheese', 'toast'],
          op_row: ['AND', 'begins_with', 'AND'],
          search_field_row: ['title', 'notes', 'all_fields'],
          boolean_row: ['OR', 'AND'] })
        end
      end

      context 'boolean, op, or search_field keys are completely missing' do
        it 'returns params with default booleans, ops, or search_fields' do
          params = search_builder.remove_blank_rows({ q_row: ['pickles', 'cheese', 'toast'] })
          expect(params).to eq({ q_row: ['pickles', 'cheese', 'toast'],
          op_row: ['AND', 'AND', 'AND'],
          search_field_row: ['all_fields', 'all_fields', 'all_fields'],
          boolean_row: ['AND', 'AND'] })
        end
      end
    end
  end

  describe '#clean_q_rows' do
    context 'query with parentheses or brackets' do
      it 'removes all parentheses and brackets' do
        params = { q_row: ['(oh hello) here [are] some (cool) special c[h]aracters'] }
        expect(search_builder.clean_q_rows(params)).to eq(['oh hello here are some cool special characters'])
      end
    end

    context 'query with left and right quotation marks' do
      it 'replaces with standard quotation marks' do
        params = { q_row: ["”a doll's house“"] }
        expect(search_builder.clean_q_rows(params)).to eq(['"a doll\'s house"'])
      end
    end

    context 'query with paired quotation marks' do
      it 'does not change the query' do
        params = { q_row: ['"a doll\'s house" "henrik ibsen"', '"just one pair of quotes"'] }
        expect(search_builder.clean_q_rows(params)).to eq(['"a doll\'s house" "henrik ibsen"', '"just one pair of quotes"'])
      end
    end

    context 'query with unpaired quotation marks' do
      it 'closes the quotation if query starts with quotation mark' do
        params = { q_row: ['"oh hey there'] }
        expect(search_builder.clean_q_rows(params)).to eq(['"oh hey there"'])
      end

      it 'removes all other quotation marks' do
        params = { q_row: ['oh hey "there', '"oh hey "there"'] }
        expect(search_builder.clean_q_rows(params)).to eq(['oh hey there', 'oh hey there'])
      end
    end

    context 'query with escapable special characters' do
      it 'escapes all special characters' do
        params = { q_row: ['oh: hi', 'fun:colon:times', '(fancy seeing [you!] - yes, you + your friend - here)'] }
        expect(search_builder.clean_q_rows(params)).to eq(['oh\: hi', 'fun\:colon\:times', 'fancy seeing you! \- yes, you \+ your friend \- here'])
      end
    end
  end

  describe '#q_with_quotes_to_solr' do
    let(:search_field) { 'title' }
    let(:search_field_config) { blacklight_config.search_fields[search_field] }

    context 'query with quotation marks' do
      let(:q) { '"a doll\'s house"' }

      context 'op = all' do
        let(:op) { 'AND' }

        it 'returns query with quoted field' do
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('(title_quoted:"a doll\'s house")')
        end
      end

      context 'op = any' do
        let(:op) { 'OR' }

        it 'returns query with quoted field' do
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('(title_quoted:"a doll\'s house")')
        end
      end

      context 'op = phrase' do
        let(:op) { 'phrase' }

        it 'returns query with quoted field' do
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('title_quoted:"a doll\'s house"')
        end
      end

      context 'op = begins with' do
        let(:op) { 'begins_with' }

        it 'returns query with starts field' do
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('title_starts:"a doll\'s house"')
        end
      end
    end

    context 'query with multiple quotation marks' do
      let(:op) { 'AND' }

      context 'op = all' do  
        it 'returns query with multiple quoted fields' do
          q = '"a doll\'s house" "henrik ibsen"'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('(title_quoted:"a doll\'s house") AND (title_quoted:"henrik ibsen")')
        end

        it 'returns query with mixed quoted and non-quoted fields' do
          q = '"a doll\'s house" henrik ibsen'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('(title_quoted:"a doll\'s house") AND ((title:"henrik" AND title:"ibsen") OR title_phrase:"henrik ibsen")')
        end
      end

      context 'op = any' do
        let(:op) { 'OR' }

        it 'returns query with multiple quoted fields' do
          q = '"a doll\'s house" "henrik ibsen"'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('(title_quoted:"a doll\'s house") OR (title_quoted:"henrik ibsen")')
        end

        it 'returns query with mixed quoted and non-quoted fields' do
          q = '"a doll\'s house" henrik ibsen'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
          to eq('(title_quoted:"a doll\'s house") OR (title:"henrik" OR title:"ibsen")')
        end

      end

      context 'op = phrase' do
        let(:op) { 'phrase' }

        it 'returns query with quoted field' do
          q = '"a doll\'s house" "henrik ibsen"'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('title_quoted:"a doll\'s house henrik ibsen"')
        end

        it 'returns query with quoted field' do
          q = '"a doll\'s house" henrik ibsen'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
          to eq('title_quoted:"a doll\'s house henrik ibsen"')
        end
      end

      context 'op = begins with' do
        let(:op) { 'begins_with' }
  
        it 'returns query with starts field' do
          q = '"a doll\'s house" "henrik ibsen"'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('title_starts:"a doll\'s house henrik ibsen"')
        end

        it 'returns query with starts field' do
          q = '"a doll\'s house" henrik ibsen'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
          to eq('title_starts:"a doll\'s house henrik ibsen"')
        end
      end
    end

    context 'irregular quotation mark usage' do
      let(:op) { 'AND' }

      # This shouldn't actually happen because q should have gotten cleaned up in clean_q_rows
      context 'query with unpaired quotation marks' do
        let(:q) { '"a doll\'s house' }

        it 'treats everything after leftover quotation mark as quoted' do
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('(title_quoted:"a doll\'s house")')
        end
      end

      context 'query has empty quotation marks' do
        it 'parses only the text and ignores the empty quote' do
          q = 'empty quote ""'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).
            to eq('((title:"empty" AND title:"quote") OR title_phrase:"empty quote")')
        end

        it 'returns an empty string if no other text' do
          q = '""'
          expect(search_builder.q_with_quotes_to_solr(q, op, search_field, search_field_config)).to eq('')
        end
      end
    end
  end

  describe '#set_q_fields' do
    let(:params) { { op_row: op_row, search_field_row: search_field_row, q_row: q_row } }

    context '1 search term' do
      let(:q_row) { ['cats'] }

      context 'all_fields' do
        let(:search_field_row) { ['all_fields'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['("cats") OR phrase:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['starts:"cats"'])
          end
        end
      end

      context 'title' do
        let(:search_field_row) { ['title'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(title:"cats") OR title_phrase:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['title:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['title_quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['title_starts:"cats"'])
          end
        end
      end

      context 'journaltitle' do
        let(:search_field_row) { ['journaltitle'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['((title:"cats") OR title_phrase:"cats") AND format:"Journal/Periodical"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(title:"cats") AND format:"Journal/Periodical"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(title_quoted:"cats") AND format:"Journal/Periodical"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(title_starts:"cats") AND format:"Journal/Periodical"'])
          end
        end
      end

      context 'author' do
        let(:search_field_row) { ['author'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['author:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['author:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['author_quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['author_starts:"cats"'])
          end
        end
      end

      context 'subject' do
        let(:search_field_row) { ['subject'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['subject:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['subject:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['subject_quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['subject_starts:"cats"'])
          end
        end
      end

      context 'lc_callnum' do
        let(:search_field_row) { ['lc_callnum'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['lc_callnum:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['lc_callnum:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['lc_callnum:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['lc_callnum_starts:"cats"'])
          end
        end
      end

      context 'publisher' do
        let(:search_field_row) { ['publisher'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['publisher:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['publisher:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['publisher_quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['publisher_starts:"cats"'])
          end
        end
      end

      context 'pubplace' do
        let(:search_field_row) { ['pubplace'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['pubplace:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['pubplace:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['pubplace_quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['pubplace_starts:"cats"'])
          end
        end
      end

      context 'number' do
        let(:search_field_row) { ['number'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(number:"cats") OR number_phrase:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['number:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['number_quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['number_starts:"cats"'])
          end
        end
      end

      context 'isbnissn' do
        let(:search_field_row) { ['isbnissn'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['isbnissn:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['isbnissn:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['isbnissn_quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['isbnissn_starts:"cats"'])
          end
        end
      end

      context 'notes' do
        let(:search_field_row) { ['notes'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['notes:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['notes:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['notes_quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['notes_starts:"cats"'])
          end
        end
      end

      context 'donor' do
        let(:search_field_row) { ['donor'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['donor:"cats"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['donor:"cats"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['donor_quoted:"cats"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['donor_starts:"cats"'])
          end
        end
      end
    end

    context 'multiple search terms in 1 query' do
      let(:q_row) { ['cats dogs'] }

      context 'all_fields' do
        let(:search_field_row) { ['all_fields'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['("cats" AND "dogs") OR phrase:"cats dogs"'])
          end

          context 'with quotation marks' do
            let(:q_row) { ['"cats dogs"']}
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['"cats" OR "dogs"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['quoted:"cats dogs"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['starts:"cats dogs"'])
          end
        end
      end

      context 'title' do
        let(:search_field_row) { ['title'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(title:"cats" AND title:"dogs") OR title_phrase:"cats dogs"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['title:"cats" OR title:"dogs"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['title_quoted:"cats dogs"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['title_starts:"cats dogs"'])
          end
        end
      end

      context 'journaltitle' do
        let(:search_field_row) { ['journaltitle'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['((title:"cats" AND title:"dogs") OR title_phrase:"cats dogs") AND format:"Journal/Periodical"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(title:"cats" OR title:"dogs") AND format:"Journal/Periodical"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(title_quoted:"cats dogs") AND format:"Journal/Periodical"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(title_starts:"cats dogs") AND format:"Journal/Periodical"'])
          end
        end
      end

      context 'lc_callnum' do
        let(:search_field_row) { ['lc_callnum'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'does not break up solr query' do
            expect(search_builder.set_q_fields(params)).to eq(['lc_callnum:"cats dogs"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['lc_callnum:"cats" OR lc_callnum:"dogs"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'does not break up solr query, does not use a special quoted field' do
            expect(search_builder.set_q_fields(params)).to eq(['lc_callnum:"cats dogs"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['lc_callnum_starts:"cats dogs"'])
          end
        end
      end

      context 'publisher' do
        let(:search_field_row) { ['publisher'] }

        context 'op = all' do
          let(:op_row) { ['AND'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['(publisher:"cats" AND publisher:"dogs") OR publisher:"cats dogs"'])
          end
        end

        context 'op = any' do
          let(:op_row) { ['OR'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['publisher:"cats" OR publisher:"dogs"'])
          end
        end

        context 'op = phrase' do
          let(:op_row) { ['phrase'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['publisher_quoted:"cats dogs"'])
          end
        end

        context 'op = begins with' do
          let(:op_row) { ['begins_with'] }

          it 'returns new q_row with solr fields included' do
            expect(search_builder.set_q_fields(params)).to eq(['publisher_starts:"cats dogs"'])
          end
        end
      end
    end

    context 'multiple queries' do
      let(:q_row) { ['cats dogs', 'pets'] }
      let(:op_row) { ['AND', 'OR'] }
      let(:search_field_row) { ['all_fields', 'donor'] }

      it 'returns a list with multiple queries containing solr field names' do
        expect(search_builder.set_q_fields(params)).to eq(['("cats" AND "dogs") OR phrase:"cats dogs"', 'donor:"pets"'])
      end
    end

    context 'invalid values' do
      let(:q_row) { ['A Doll\'s House'] }

      context 'invalid op' do
        let(:op_row) { ['invalid'] }
        let(:search_field_row) { ['all_fields'] }

        it 'defaults to handling op as AND/all' do
          expect(search_builder.set_q_fields(params)).to eq(['("A" AND "Doll\'s" AND "House") OR phrase:"A Doll\'s House"'])
        end
      end

      context 'missing op' do
        let(:op_row) { [] }
        let(:search_field_row) { ['all_fields'] }

        it 'defaults to handling op as AND/all' do
          expect(search_builder.set_q_fields(params)).to eq(['("A" AND "Doll\'s" AND "House") OR phrase:"A Doll\'s House"'])
        end
      end

      context 'invalid search_field' do
        let(:op_row) { ['AND'] }
        let(:search_field_row) { ['invalid'] }

        it 'defaults to search field as solr field' do
          expect(search_builder.set_q_fields(params)).to eq(['(invalid:"A" AND invalid:"Doll\'s" AND invalid:"House") OR invalid:"A Doll\'s House"'])
        end
      end

      context 'missing search_field' do
        let(:op_row) { ['AND'] }
        let(:search_field_row) { [] }

        it 'defaults to query with no search field set' do
          expect(search_builder.set_q_fields(params)).to eq(['("A" AND "Doll\'s" AND "House") OR "A Doll\'s House"'])
        end
      end
    end
  end

  describe '#build_advanced_search_query' do
    context 'unexpected q_row' do
      it 'returns nil if q_row is missing or not an array' do
        expect(search_builder.build_advanced_search_query({ q_row: 'invalid' })).to eq('')
        expect(search_builder.build_advanced_search_query({ })).to eq('')
      end
    end

    context 'q_row only has characters that will be stripped' do
      it 'returns nil' do
        expect(search_builder.build_advanced_search_query({
          q_row: ['()[]'], op_row: ['AND'], search_field_row: ['all_fields']
        })).to eq('')
      end
    end

    context 'valid params' do
      it 'returns a formatted query string' do
        expect(search_builder.build_advanced_search_query({
          q_row: ['cats dogs', 'pets'], op_row: ['AND', 'AND'], search_field_row: ['all_fields', 'title'], boolean_row: { '1' => 'OR' }
        })).to eq('((("cats" AND "dogs") OR phrase:"cats dogs") OR ((title:"pets") OR title_phrase:"pets"))')
      end
    end
  end

  describe '#advsearch' do
    before do
      allow(search_builder).to receive(:blacklight_params) { blacklight_params }
    end

    # TODO: Commented out expects are the expected behavior, but the actual behavior is different. Need to confirm and fix.
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
          end
        end

        context 'multiple search terms' do
          let(:q) { 'test1 test2 test3'}

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('("test1" AND "test2"  AND "test3") OR phrase:"test1 test2 test3"')
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
            expect(solr_params[:q]).to eq('(("test") OR phrase:"test")')
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
            expect(solr_params[:q]).to eq('(("test1" AND "test2") OR phrase:"test1 test2")')
          end
        end

        context 'query ANY search term' do
          let(:user_params) { {
            q_row: ['test1 test2'],
            op_row: ['OR'],
            search_field_row: [search_field],
            boolean_row: {}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('("test1" OR "test2")')
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
            expect(solr_params[:q]).to eq('(quoted:"test1 test2")')
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
            expect(solr_params[:q]).to eq('(starts:"test1 test2")')
          end
        end

        context 'query 1 AND query 2' do
          let(:user_params) { {
            q_row: ['pickle cheese', 'dill'],
            op_row: ['AND', 'AND'],
            search_field_row: [search_field, search_field],
            boolean_row: {"1" => "AND"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((("pickle" AND "cheese") OR phrase:"pickle cheese") AND (("dill") OR phrase:"dill"))')
          end
        end

        context 'query 1 OR query 2' do
          let(:user_params) { {
            q_row: ['pickle cheese', 'dill'],
            op_row: ['AND', 'AND'],
            search_field_row: [search_field, search_field],
            boolean_row: {"1" => "OR"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((("pickle" AND "cheese") OR phrase:"pickle cheese") OR (("dill") OR phrase:"dill"))')
          end
        end

        context 'query 1 NOT query 2' do
          let(:user_params) { {
            q_row: ['pickle cheese', 'dill'],
            op_row: ['AND', 'AND'],
            search_field_row: [search_field, search_field],
            boolean_row: {"1" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((("pickle" AND "cheese") OR phrase:"pickle cheese") NOT (("dill") OR phrase:"dill"))')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          # Wow there are really a lot of parentheses
          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(((((((("test1" AND "test2") OR phrase:"test1 test2")' \
                                          ' AND ((quoted:"test3 test4")))' \
                                          ' AND ("test5" OR "test6"))' \
                                          ' AND (starts:"test7 test8"))' \
                                          ' AND (quoted:"test9 test10"))' \
                                          ' OR (("test11" AND "test12") OR phrase:"test11 test12"))' \
                                          ' NOT (("test13" AND "test14") OR phrase:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('((title:"test") OR title_phrase:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((title:"test1" AND title:"test2") OR title_phrase:"test1 test2")' \
              ' AND ((title_quoted:"test3 test4")))' \
              ' AND (title:"test5" OR title:"test6"))' \
              ' AND (title_starts:"test7 test8"))' \
              ' AND (title_quoted:"test9 test10"))' \
              ' OR ((title:"test11" AND title:"test12") OR title_phrase:"test11 test12"))' \
              ' NOT ((title:"test13" AND title:"test14") OR title_phrase:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('(((title:"test") OR title_phrase:"test") AND format:"Journal/Periodical")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(((((((((title:"test1" AND title:"test2") OR title_phrase:"test1 test2") AND format:"Journal/Periodical")' \
                                          ' AND (((title_quoted:"test3 test4")) AND format:"Journal/Periodical"))' \
                                          ' AND ((title:"test5" OR title:"test6") AND format:"Journal/Periodical"))' \
                                          ' AND ((title_starts:"test7 test8") AND format:"Journal/Periodical"))' \
                                          ' AND ((title_quoted:"test9 test10") AND format:"Journal/Periodical"))' \
                                          ' OR (((title:"test11" AND title:"test12") OR title_phrase:"test11 test12") AND format:"Journal/Periodical"))' \
                                          ' NOT (((title:"test13" AND title:"test14") OR title_phrase:"test13 test14") AND format:"Journal/Periodical"))')
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
            expect(solr_params[:q]).to eq('(author:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((author:"test1" AND author:"test2") OR author:"test1 test2")' \
                                          ' AND ((author_quoted:"test3 test4")))' \
                                          ' AND (author:"test5" OR author:"test6"))' \
                                          ' AND (author_starts:"test7 test8"))' \
                                          ' AND (author_quoted:"test9 test10"))' \
                                          ' OR ((author:"test11" AND author:"test12") OR author:"test11 test12"))' \
                                          ' NOT ((author:"test13" AND author:"test14") OR author:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('(subject:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((subject:"test1" AND subject:"test2") OR subject:"test1 test2")' \
                                          ' AND ((subject_quoted:"test3 test4")))' \
                                          ' AND (subject:"test5" OR subject:"test6"))' \
                                          ' AND (subject_starts:"test7 test8"))' \
                                          ' AND (subject_quoted:"test9 test10"))' \
                                          ' OR ((subject:"test11" AND subject:"test12") OR subject:"test11 test12"))' \
                                          ' NOT ((subject:"test13" AND subject:"test14") OR subject:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('(lc_callnum:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('(((((((lc_callnum:"test1 test2")' \
                                          ' AND ((lc_callnum:"test3 test4")))' \
                                          ' AND (lc_callnum:"test5" OR lc_callnum:"test6"))' \
                                          ' AND (lc_callnum_starts:"test7 test8"))' \
                                          ' AND (lc_callnum:"test9 test10"))' \
                                          ' OR (lc_callnum:"test11 test12"))' \
                                          ' NOT (lc_callnum:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('(series:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((series:"test1" AND series:"test2") OR series:"test1 test2")' \
                                          ' AND ((series_quoted:"test3 test4")))' \
                                          ' AND (series:"test5" OR series:"test6"))' \
                                          ' AND (series_starts:"test7 test8"))' \
                                          ' AND (series_quoted:"test9 test10"))' \
                                          ' OR ((series:"test11" AND series:"test12") OR series:"test11 test12"))' \
                                          ' NOT ((series:"test13" AND series:"test14") OR series:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('(publisher:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((publisher:"test1" AND publisher:"test2") OR publisher:"test1 test2")' \
                                          ' AND ((publisher_quoted:"test3 test4")))' \
                                          ' AND (publisher:"test5" OR publisher:"test6"))' \
                                          ' AND (publisher_starts:"test7 test8"))' \
                                          ' AND (publisher_quoted:"test9 test10"))' \
                                          ' OR ((publisher:"test11" AND publisher:"test12") OR publisher:"test11 test12"))' \
                                          ' NOT ((publisher:"test13" AND publisher:"test14") OR publisher:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('(pubplace:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((pubplace:"test1" AND pubplace:"test2") OR pubplace:"test1 test2")' \
                                          ' AND ((pubplace_quoted:"test3 test4")))' \
                                          ' AND (pubplace:"test5" OR pubplace:"test6"))' \
                                          ' AND (pubplace_starts:"test7 test8"))' \
                                          ' AND (pubplace_quoted:"test9 test10"))' \
                                          ' OR ((pubplace:"test11" AND pubplace:"test12") OR pubplace:"test11 test12"))' \
                                          ' NOT ((pubplace:"test13" AND pubplace:"test14") OR pubplace:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('((number:"test") OR number_phrase:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((number:"test1" AND number:"test2") OR number_phrase:"test1 test2")' \
                                          ' AND ((number_quoted:"test3 test4")))' \
                                          ' AND (number:"test5" OR number:"test6"))' \
                                          ' AND (number_starts:"test7 test8"))' \
                                          ' AND (number_quoted:"test9 test10"))' \
                                          ' OR ((number:"test11" AND number:"test12") OR number_phrase:"test11 test12"))' \
                                          ' NOT ((number:"test13" AND number:"test14") OR number_phrase:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('(isbnissn:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((isbnissn:"test1" AND isbnissn:"test2") OR isbnissn:"test1 test2")' \
                                          ' AND ((isbnissn_quoted:"test3 test4")))' \
                                          ' AND (isbnissn:"test5" OR isbnissn:"test6"))' \
                                          ' AND (isbnissn_starts:"test7 test8"))' \
                                          ' AND (isbnissn_quoted:"test9 test10"))' \
                                          ' OR ((isbnissn:"test11" AND isbnissn:"test12") OR isbnissn:"test11 test12"))' \
                                          ' NOT ((isbnissn:"test13" AND isbnissn:"test14") OR isbnissn:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('(notes:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((notes:"test1" AND notes:"test2") OR notes:"test1 test2")' \
                                          ' AND ((notes_quoted:"test3 test4")))' \
                                          ' AND (notes:"test5" OR notes:"test6"))' \
                                          ' AND (notes_starts:"test7 test8"))' \
                                          ' AND (notes_quoted:"test9 test10"))' \
                                          ' OR ((notes:"test11" AND notes:"test12") OR notes:"test11 test12"))' \
                                          ' NOT ((notes:"test13" AND notes:"test14") OR notes:"test13 test14"))')
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
            expect(solr_params[:q]).to eq('(donor:"test")')
          end
        end

        context 'combination query' do
          let(:user_params) { {
            q_row: ['test1 test2', '"test3 test4"', 'test5 test6', 'test7 test8', 'test9 test10', 'test11 test12', 'test13 test14'],
            op_row: ['AND', 'AND', 'OR', 'begins_with', 'phrase', 'AND', 'AND'],
            search_field_row: Array.new(7) { search_field },
            boolean_row: {"1" => "AND", "2" => "AND", "3" => "AND", "4" => "AND", "5" => "OR", "6" => "NOT"}
          } }

          it 'transforms expected solr params' do
            search_builder.advsearch(solr_params)
            expect(solr_params[:q]).to eq('((((((((donor:"test1" AND donor:"test2") OR donor:"test1 test2")' \
                                          ' AND ((donor_quoted:"test3 test4")))' \
                                          ' AND (donor:"test5" OR donor:"test6"))' \
                                          ' AND (donor_starts:"test7 test8"))' \
                                          ' AND (donor_quoted:"test9 test10"))' \
                                          ' OR ((donor:"test11" AND donor:"test12") OR donor:"test11 test12"))' \
                                          ' NOT ((donor:"test13" AND donor:"test14") OR donor:"test13 test14"))')
          end
        end
      end
    end
  end
end
