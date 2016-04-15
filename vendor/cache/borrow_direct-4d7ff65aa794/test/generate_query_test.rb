# Encoding: UTF-8

require 'test_helper'
require 'uri'
require 'cgi'

describe "GenerateQuery" do
  before do
    @test_base = "http://example.org"
  end

  describe "query_url_with" do

    it "raises on unknown field" do
      assert_raises(ArgumentError) do
        BorrowDirect::GenerateQuery.new(@test_base).query_url_with(:invalid_thing => "foo")
      end
    end

    it "generates query" do
      generate_query = BorrowDirect::GenerateQuery.new(@test_base)

      url = generate_query.query_url_with(:title => "This is a title", :author => "This is an author")

      assert url.start_with? @test_base

      parsed_url = URI.parse(url)
      url_query  = CGI.parse( parsed_url.query )

      assert_present url_query

      assert_length 1, url_query["query"]

      query_text = url_query["query"].first

      parts = query_text.split(" and ")

      assert_length 2, parts

      assert_include parts, 'ti="This is a title"'
      assert_include parts, 'au="This is an author"'
    end

    it "ignores nil arguments" do
      generate_query = BorrowDirect::GenerateQuery.new(@test_base)

      url = generate_query.query_url_with(:title => "This is a title", :author => nil)

      parsed_url = URI.parse(url)
      url_query  = CGI.parse( parsed_url.query )

      assert_present url_query

      assert_length 1, url_query["query"]

      query_text = url_query["query"].first

      parts = query_text.split(" and ")

      assert_length 1, parts

      assert_include parts, 'ti="This is a title"'
    end
  end

  describe "with string arg" do
    it "generates supplied query" do
      generate_query = BorrowDirect::GenerateQuery.new(@test_base)

      query = %Q{isbn="#{BorrowDirect::GenerateQuery.escape('1212')}" and (ti="#{BorrowDirect::GenerateQuery.escape('foo')}" or ti="#{BorrowDirect::GenerateQuery.escape('bar')}")}

      url = generate_query.query_url_with(query)

      parsed_url = URI.parse(url)
      url_query  = CGI.parse( parsed_url.query )
      assert_present url_query
      assert_length 1, url_query["query"]

      assert_equal query, url_query["query"].first
    end
  end

  describe "#normalized_author_title_params" do
    before do
      @generator = BorrowDirect::GenerateQuery.new(@test_base)
    end
    it "raises without good arguments" do
      assert_raises(ArgumentError) {@generator.normalized_author_title_params(nil)}
    end

    it "passes through simple author and title" do
      author ="John Smith"
      title = "Some Book"
      assert_equal( {:title => "some book", :author => 'john smith'}, @generator.normalized_author_title_params(:author => author, :title => title))
    end

    it "works with just a title" do
      title  = "Some Book"
      expected = {:title => "some book"}
      assert_equal expected, @generator.normalized_author_title_params(:title => title)
      assert_equal expected, @generator.normalized_author_title_params(:title => title, :author => nil)
      assert_equal expected, @generator.normalized_author_title_params(:title => title, :author => "")
    end

    it "title remove trailing parens" do
      title = "A Book (really bad one)"

      assert_equal( {:title => "a book"}, @generator.normalized_author_title_params(:title => title))
    end

    it "title strip subtitles" do
      assert_equal({:title => "a book"}, @generator.normalized_author_title_params(:title => "A Book: Subtitle"))
      assert_equal({:title => "a book"}, @generator.normalized_author_title_params(:title => "A Book; and more"))
    end

    it "limit to first 5 words" do
      assert_equal({:title => "one two's three four five"}, @generator.normalized_author_title_params(:title => "One Two's Three Four Five Six Seven"))
    end

    it "okay with unicode, strip punct" do
      assert_equal({:title => "el revolución"}, @generator.normalized_author_title_params(:title => "El   Revolución!: Cuban poster art"))
    end

    it "normalizes author to what looks like last name" do
      assert_equal({:title => "book", :author => "scott"}, @generator.normalized_author_title_params(:title => "Book", :author => "Scott, James C"))
    end

    it "full normalized_author_title_query" do
      url = @generator.normalized_author_title_query(:title => "A Book: Subtitle", :author => "Smith, John" )
      query = assert_bd_query_url(url)
    end

    it "handles combining diacritics" do
      # Some of the code we started with had a problem with combining diacritics. 
      a_acute_combined = [97, 204, 129].pack("c*").force_encoding("UTF-8")

      orig_title = "Vel#{a_acute_combined}squez's stuff...."

      normalized_title = @generator.normalized_title(orig_title)

      assert_equal "vel#{a_acute_combined}squez's stuff", normalized_title
    end

    it "preserves apostrophes" do
      assert_equal "c l r james's caribbean", @generator.normalized_title("C L R James's Caribbean")
    end 

    it "allows ampersands" do
      assert_equal "x & y", @generator.normalized_title("x & y")
    end


    it "gets author reasonably out of some 245c type things" do
      assert_equal "edward foster", @generator.normalized_author("edited by Edward Foster")
      assert_equal "edward foster", @generator.normalized_author("by Edward Foster")

      assert_equal "leonard diepeveen", @generator.normalized_author("edited by Leonard Diepeveen.")

      assert_equal "amalia avramidou", @generator.normalized_author("edited by Amalia Avramidou and Denise Demetriou.")
      assert_equal "james elkins", @generator.normalized_author("edited by James Elkins and Robert Williams.")

      # Hmm, should we really be stripping those periods? Not sure, but seems
      # to do okay in searching. 
      assert_equal "h a shapiro", @generator.normalized_author("edited by H.A. Shapiro.")

      assert_equal "john smith", @generator.normalized_author("john smith, editor, mike brown, editor")
      assert_equal "john smith", @generator.normalized_author("by john smith; with help from mike brown")
    end


  end

  def assert_bd_query_url(url)
    assert_present url

    parsed_url = URI.parse(url)
    url_query  = CGI.parse( parsed_url.query )
    assert_present url_query
    assert_length 1, url_query["query"]

    return url_query["query"].first
  end

end