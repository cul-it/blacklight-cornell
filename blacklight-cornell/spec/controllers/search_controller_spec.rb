# spec/controllers/search_controller_spec.rb
require "rails_helper"

RSpec.describe SearchController, type: :controller do
  describe "SearchController.transform_query" do
    it "transforms the query correctly" do
      query = "going fishing"
      transformed_query = SearchController.transform_query(query)
      expect(transformed_query).to eq('("going" AND "fishing") OR phrase:"going fishing"')
    end

    it "handles already-quoted queries correctly" do
      # pending("Pending implementation of handling already-quoted queries")
      query = '"going fishing"'
      transformed_query = SearchController.transform_query(query)
      expect(transformed_query).to eq("\"going fishing\"")
    end

    it "handles single-term queries correctly" do
      query = "fishing"
      transformed_query = SearchController.transform_query(query)
      expect(transformed_query).to eq('("fishing") OR phrase:"fishing"')
    end

    it "handles apostrophised queries correctly" do
      query = "a doll's house"
      transformed_query = SearchController.transform_query(query)
      expect(transformed_query).to eq('("a" AND "doll\'s" AND "house") OR phrase:"a doll\'s house"')
    end

    it "handles embedded quoted queries correctly" do
      # pending("Pending implementation of handling embedded quoted queries")
      query = "A \"fish finder\" going fishing offshore"
      transformed_query = SearchController.transform_query(query)
      expect(transformed_query).to eq("A \"fish finder\" going fishing offshore")
    end

    it "handles empty queries correctly" do
      # pending("Pending implementation of handling empty queries")
      query = ""
      transformed_query = SearchController.transform_query(query)
      expect(transformed_query).to eq("() OR phrase:\"\"")
    end
  end
end
