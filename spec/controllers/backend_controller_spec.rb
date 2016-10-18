 require 'spec_helper'
# require 'backend_controller'

describe BackendController, :type => :controller  do
  describe "GET 'holdings_short" do
    it "returns a successful 200 response" do
       get :holdings_short, format: :json, :id =>"1449"
      expect(response).to be_success
    end
  end

  describe "GET 'holdings_short'" do
    before { get :holdings_short , :id => "1449" }
    it "Gives back JSON" do
      #expect(response).to render_template("holdings_short")
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['1449']['records'][0]['bibid']).to  eq("1449")
      expect(parsed_body['1449']['records'][0]['holding_id']).to  eq("5817")
    end
  end

  describe "GET 'holdings_shorthm" do
    it "returns a successful 200 response" do
       get :holdings_shorthm, format: :html, :id =>"1449"
      expect(response).to be_success
    end
  end

  describe "GET 'holdings_shorthm'" do
    before { get :holdings_shorthm , :id => "1449" }
    it "renders the holdings_short template" do
      #expect(response).to render_template("holdings_short")
      expect(response).to render_template("backend/holdings_short")
    end
  end



end
