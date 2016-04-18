[![Gem Version](https://badge.fury.io/rb/borrow_direct.svg)](http://badge.fury.io/rb/borrow_direct)
[![Build Status](https://travis-ci.org/jrochkind/borrow_direct.svg)](https://travis-ci.org/jrochkind/borrow_direct)

# BorrowDirect

Ruby tools for programmatic access to BorrowDirect consortial system, powered by Relais D2D software. 

Using API as well as deep-linking to search results and possibly other stuff. 

May also work with other Relais D2D setups with configuration or changes, no idea. 

## Usage

Some configuration at boot, perhaps in a Rails initializer:

~~~ruby
# REQUIRED: Set your BD api_key
BorrowDirect::Defaults.api_key = "your bd api key"

# Or, you likely have a different api key for production and
# testing/dev, if in Rails this is one way to handle that:
BorrowDirect::Defaults.api_key = Rails.env.production? ? "production_bd_api" : "dev_bd_api"
  

# Uses BD Test system by defualt, if you want to use production system instead
BorrowDirect::Defaults.api_base = BorrowDirect::Defaults::PRODUCTION_API_BASE

# Set a default BD LibrarySymbol for your library
BorrowDirect::Defaults.library_symbol = "YOURSYMBOL"

# If you want to do FindItem requests with a default generic patron
# barcode
BorrowDirect::Defaults.find_item_patron_barcode = "9999999"

# BorrowDirect can take an awful long time to respond sometimes. 
# How long are you willing to wait? (Seconds, default 30)
BorrowDirect::Defaults.timeout = 10
~~~

Then you can do things. 

### Find an item's requestability (FindItem api)

~~~ruby
# with default generic patron set in config find_item_patron_barcode
response = BorrowDirect::FindItem.new.find(:isbn => "1212121212")
# Returns a BorrowDirect::FindItem::Response
response.requestable?  
response.pickup_locations

# Or with specific patron, with default library symbol
BorrowDirect::FindItem.new(patron_barcode).find(:isbn => "121212").requestable?
~~~


### Make a request (RequestItem api)
~~~ruby
request_number = BorrowDirect::RequestItem.new(patron_barcode).make_request(pickup_location, :isbn => "1212121212")
# Will return request number, or nil if couldn't be requested. 
# Or, use make_request! (with exclamation point) to raise if
# can't be requested. 
~~~

### Get patron's current requests (RequestQuery api)

~~~ruby
items = BorrowDirect::RequestQuery.new(patron_barcode).requests
# Returns an array of BorrowDirect::RequestQuery::Item
items.each do |item|
   item.request_number
   item.title 
   item.date_submitted # a ruby DateTime
   item.request_status
end

# Or use a BD 'type' argument
BorrowDirect::RequestQuery.new(patron_barcode).requests("open")
~~~

### AuthID's

All BD API's will requires an AuthorizationID as of late summer/fall 2015. 
Our ruby API still accepts a barcode/library symbol pair instead, with both values possibly
coming from configured local deaults. The ruby code will make a separate request to retrieve
the AuthorizationID behind the scenes, so it can use it. 

If you already have an AuthorizationID, you can set pass it in to re-use, and avoid
the extra call, using #with_auth_id on any BD API request. 

~~~ruby
response = BorrowDirect::FindItem.new(patron_barcode).find(:isbn => isbn)
auth_id  = response.auth_id

BorrowDirect::RequestItem.new(patron_barcode).with_auth_id(auth_id).make_request(pickup_location, :isbn => isbn)
~~~

If you pass in an expired or bad AID, we should raise a BorrowDirect::InvalidAidError.
(Some unpredictability and inconsistency in remote system error messages may
prevent us from catching and classing as an InvalidAidError, if you notice report
and we'll try to fix or report upstream.)

### Generate a query into BorrowDirect

Sometimes you may want to send the user to specific search results inside the standard BorrowDirect HTML interface. We include a helper class for generating such queries. 

This helper class currently assumes you run a front-end "redirect" script to authenticate your users and send them to BorrowDirect, and depends on that. You will need to ensure your script also takes any`query=X` URL query parameter sent to it, and includes this in the auth redirect to BorrowDirect. 

~~~ruby
BorrowDirect::Defaults.html_base_url = "https://university.edu/borrow_direct_auth_redirector"

# Generate a link to search results:
BorrowDirect::GenerateQuery.new.query_url_with(:isbn => "1234435445")

# Multiple fields can be included, their values will be treated
# as phrase searches, and boolean AND'd together. All the fields
# from the BorrowDirect "advanced search" are supported
BorrowDirect::GenerateQuery.new.query_url_with(
    :author => "John Smith", 
    :title => "Some Book",
    :keyword => "stuff",
    :subject => "medicine",
    :isbn => "1234435445")
~~~

Or specify your own query passed as a string, possibly a complex one
using BD's undocumented syntax that you figure out. Use `
BorrowDirect::GenerateQuery.escape` to escape values, but don't CGI escape the input. 

~~~ruby
query = %Q{isbn="#{BorrowDirect::GenerateQuery.escape('1212')}" and (ti="#{BorrowDirect::GenerateQuery.escape('foo')}" or ti="#{BorrowDirect::GenerateQuery.escape('bar')}")}
BorrowDirect::GenerateQuery.new.query_url_with query
~~~

For the common case of doing an author-title keyword search, this gem has some suggested
normalization it applies to author and title, to maximize chances of succesful hits.
(limiting to 5 words in title, searching on main title only not subtitle, etc.)

~~~ruby
BorrowDirect::GenerateQuery.new.normalized_author_title_query(:title => some_title, :author => some_author)
~~~

### Errors

In error conditions, a BorrowDirect::Error may be thrown -- including request timeouts when
BD is taking too long to respond. You can set timeout value with default config, or
for each api object.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'borrow_direct'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install borrow_direct

## Running tests

Test coverage is with Minitest::Spec -- if more convenient, you can use Minitest::Unit
style instead. But we do not use rspec; and we use Minispec assertion style (assert_x) not
expectation style please (not x.must_).

Run tests with 
*`rake test`
* or a specific test file with `ruby -Ilib:test ./test/some_test.rb`

Tests are recorded with the [VCR](https://github.com/vcr/vcr) gem, 
so tests can be re-run without actually contacting BorrowDirect server, it uses
the recorded transactions. 

To re-run tests with live HTTP connections to BD
* delete all or some of the cassettes in `./test/vcr_cassettes`
* set shell ENV variables `BD_LIBRARY_SYMBOL` and `BD_PATRON` to values
  that will be used for testing, and re-recording cassettes
* There are some constants at the top of the testing file that identify
  ISBN's expected to have certain characteristics (like being requestable, or not).
  If those characteristics are not true for your library, you may need to reset
  those constants to values that meet expected conditions. 

Your barcode and library symbol credentials are not stored in the VCR cassettes,
they are filtered out. 

The tests are run against the BD test system, but the email address associated
with the `BD_PATRON` will likely still get multiple emails generated to it as a result
of testing. 

## Contributing

1. Fork it ( https://github.com/[my-github-username]/borrow_direct/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
