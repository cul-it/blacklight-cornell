require 'spec_helper'
describe "RSolr::Client" do
  
  module ClientHelper
    def client
      @client ||= (
        connection = RSolr::Connection.new
        RSolr::Client.new connection, :url => "http://localhost:9999/solr", :read_timeout => 42, :open_timeout=>43
      )
    end
  end
  
  context "initialize" do
    it "should accept whatevs and set it as the @connection" do
      RSolr::Client.new(:whatevs).connection.should == :whatevs
    end
  end
  
  context "send_and_receive" do
    include ClientHelper
    it "should forward these method calls the #connection object" do
      [:get, :post, :head].each do |meth|
        client.connection.should_receive(:execute).
            and_return({:status => 200, :body => "{}", :headers => {}})
        client.send_and_receive '', :method => meth, :params => {}, :data => nil, :headers => {}
      end
    end

    it "should be timeout aware" do
      [:get, :post, :head].each do |meth|
        client.connection.should_receive(:execute).with(client, hash_including(:read_timeout => 42, :open_timeout=>43))
        client.send_and_receive '', :method => meth, :params => {}, :data => nil, :headers => {}
      end
    end
  end

  context "post" do
    include ClientHelper
    it "should pass the expected params to the connection's #execute method" do
      request_opts = {:data => "the data", :method=>:post, :headers => {"Content-Type" => "text/plain"}}
      client.connection.should_receive(:execute).
        with(client, hash_including(request_opts)).
        and_return(
          :body => "",
          :status => 200,
          :headers => {"Content-Type"=>"text/plain"}
        )
      client.post "update", request_opts
    end
  end
  
  context "xml" do
    include ClientHelper
    it "should return an instance of RSolr::Xml::Generator" do
      client.xml.should be_a RSolr::Xml::Generator
    end
  end
  
  context "add" do
    include ClientHelper
    it "should send xml to the connection's #post method" do
      client.connection.should_receive(:execute).
        with(
          client, hash_including({
            :path => "update",
            :headers => {"Content-Type"=>"text/xml"},
            :method => :post,
            :data => "<xml/>"
          })
        ).
          and_return(
            :body => "",
            :status => 200,
            :headers => {"Content-Type"=>"text/xml"}
          )
      client.xml.should_receive(:add).
        with({:id=>1}, {:commitWith=>10}).
          and_return("<xml/>")
      client.add({:id=>1}, :add_attributes => {:commitWith=>10})
    end
  end
  
  context "update" do
    include ClientHelper
    it "should send data to the connection's #post method" do
      client.connection.should_receive(:execute).
        with(
          client, hash_including({
            :path => "update",
            :headers => {"Content-Type"=>"text/xml"},
            :method => :post,
            :data => "<optimize/>"
          })
        ).
          and_return(
            :body => "",
            :status => 200,
            :headers => {"Content-Type"=>"text/xml"}
          )
      client.update(:data => "<optimize/>")
    end
  end
  
  context "post based helper methods:" do
    include ClientHelper
    [:commit, :optimize, :rollback].each do |meth|
      it "should send a #{meth} message to the connection's #post method" do
        client.connection.should_receive(:execute).
          with(
            client, hash_including({
              :path => "update",
              :headers => {"Content-Type"=>"text/xml"},
              :method => :post,
              :data => "<?xml version=\"1.0\" encoding=\"UTF-8\"?><#{meth}/>"
            })
          ).
            and_return(
              :body => "",
              :status => 200,
              :headers => {"Content-Type"=>"text/xml"}
            )
        client.send meth
      end
    end
  end
  
  context "delete_by_id" do
    include ClientHelper
    it "should send data to the connection's #post method" do
      client.connection.should_receive(:execute).
        with(
          client, hash_including({
            :path => "update",
            :headers => {"Content-Type"=>"text/xml"},
            :method => :post,
            :data => "<?xml version=\"1.0\" encoding=\"UTF-8\"?><delete><id>1</id></delete>"
          })
        ).
          and_return(
            :body => "",
            :status => 200,
            :headers => {"Content-Type"=>"text/xml"}
          )
      client.delete_by_id 1
    end
  end
  
  context "delete_by_query" do
    include ClientHelper
    it "should send data to the connection's #post method" do
      client.connection.should_receive(:execute).
        with(
          client, hash_including({
            :path => "update",
            :headers => {"Content-Type"=>"text/xml"},
            :method => :post,
            :data => "<?xml version=\"1.0\" encoding=\"UTF-8\"?><delete><query fq=\"category:&quot;trash&quot;\"/></delete>"
          })
        ).
          and_return(
            :body => "",
            :status => 200,
            :headers => {"Content-Type"=>"text/xml"}
          )
      client.delete_by_query :fq => "category:\"trash\""
    end
  end
  
  context "adapt_response" do
    include ClientHelper
    it 'should not try to evaluate ruby when the :qt is not :ruby' do
      body = '{:time=>"NOW"}'
      result = client.adapt_response({:params=>{}}, {:status => 200, :body => body, :headers => {}})
      result.should == body
    end
    
    it 'should evaluate ruby responses when the :wt is :ruby' do
      body = '{:time=>"NOW"}'
      result = client.adapt_response({:params=>{:wt=>:ruby}}, {:status => 200, :body => body, :headers => {}})
      result.should == {:time=>"NOW"}
    end
    
    it "ought raise a RSolr::Error::InvalidRubyResponse when the ruby is indeed frugged, or even fruggified" do
      lambda {
        client.adapt_response({:params=>{:wt => :ruby}}, {:status => 200, :body => "<woops/>", :headers => {}})
      }.should raise_error RSolr::Error::InvalidRubyResponse
    end
  
  end
  
  context "build_request" do
    include ClientHelper
    it 'should return a request context array' do
      result = client.build_request('select',
        :method => :post,
        :params => {:q=>'test', :fq=>[0,1]},
        :data => "data",
        :headers => {}
      )
      [/fq=0/, /fq=1/, /q=test/, /wt=ruby/].each do |pattern|
        result[:query].should match pattern
      end
      result[:data].should == "data"
      result[:headers].should == {}
    end
    
    it "should set the Content-Type header to application/x-www-form-urlencoded; charset=UTF-8 if a hash is passed in to the data arg" do
      result = client.build_request('select',
        :method => :post,
        :data => {:q=>'test', :fq=>[0,1]},
        :headers => {}
      )
      result[:query].should == "wt=ruby"
      [/fq=0/, /fq=1/, /q=test/].each do |pattern|
        result[:data].should match pattern
      end
      result[:data].should_not match /wt=ruby/
      result[:headers].should == {"Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8"}
    end
    
  end
  
end
