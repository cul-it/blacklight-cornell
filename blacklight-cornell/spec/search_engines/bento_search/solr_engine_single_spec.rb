require 'rails_helper'

describe 'BentoSearch::SolrEngineSingle' do
  let(:solr_engine_single) { BentoSearch::SolrEngineSingle.new }

  describe '#transform_query' do
    it 'transforms the query correctly' do
      query = 'going fishing'
      transformed_query = solr_engine_single.transform_query(query)
      expect(transformed_query).to eq('("going" AND "fishing") OR phrase:"going fishing"')
    end

    it 'handles already-quoted queries correctly' do
      query = '"going fishing"'
      transformed_query = solr_engine_single.transform_query(query)
      expect(transformed_query).to eq('(quoted:"going fishing")')
    end

    it 'handles single-term queries correctly' do
      query = 'fishing'
      transformed_query = solr_engine_single.transform_query(query)
      expect(transformed_query).to eq('("fishing") OR phrase:"fishing"')
    end

    it 'handles apostrophised queries correctly' do
      query = "a doll's house"
      transformed_query = solr_engine_single.transform_query(query)
      expect(transformed_query).to eq('("a" AND "doll\'s" AND "house") OR phrase:"a doll\'s house"')
    end

    it 'handles embedded quoted queries correctly' do
      query = 'A "fish finder" going fishing offshore'
      transformed_query = solr_engine_single.transform_query(query)
      expect(transformed_query).to eq('(("A") OR phrase:"A") AND (quoted:"fish finder") AND (("going" AND "fishing" AND "offshore") OR phrase:"going fishing offshore")')
    end

    it 'handles empty queries correctly' do
      query = ''
      transformed_query = solr_engine_single.transform_query(query)
      expect(transformed_query).to eq('')
    end

    it 'does not transform queries containing booleans' do
      query = 'going AND fishing'
      transformed_query = solr_engine_single.transform_query(query)
      expect(transformed_query).to eq('going AND fishing')
    end
  end
end
