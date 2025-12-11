# frozen_string_literal: true

# Class to handle Aeon requests, particularly for holdings and item metadata
class AeonRequest
  attr_reader :holdings, :items

  def initialize(document)
    @holdings = JSON.parse(document['holdings_json'])
    @items = JSON.parse(document['items_json'] || '{}')
  end
end

# holdings_json is a holdings-uuid-keyed hash of holdings data, with the following keys within
# each holding:
#  :hrid
#  :location
#     :code
#     :name
#     :library
#     :id
#     :primaryServicePoint
#  :call
#  :items
#     :count
#     :avail
#  :circ
#  :active

# items_json is a holding-uuid-keyed hash of item data. Each holdings key corresponds to
# an array of items. Each item has the following keys:
#  :id
#  :hrid
#  :barcode
#  :copy
#  :call
#  :enum
#  :location
#     :code
#     :name
#     :library
#     :id
#     :primaryServicePoint
#  :permLocation
#  :loanType {}
#  :matType {}
#  :status
#     :status
#  :active

#  (MAYBE:)
#  :rmc
#     :ArchiveSpace Top Container
#     :Vault location

# And the final output of the holdings methods in the controller is some html and JS that looks like this:

# ret += <<~HTML
# <div>
#   <label for='iid-#{val["id"]}' class='sr-only'>iid-#{val["id"]}</label>
#   <input class='ItemNo' id='iid-#{val["id"]}' name='iid-#{val["id"]}' type='checkbox' VALUE='iid-#{val["id"]}'>
# </div>
# HTML

#                   itemdata["iid-#{val["id"].to_s}"] = {
#                     location: "#{val["rmc"]['Vault location']}",
#                     enumeration: "#{enum}",
#                     barcode: "iid-#{val["id"].to_s}",
#                     loc_code: "#{val["location"]["code"]}",
#                     chron: "",
#                     copy: "#{val["copy"].to_s}",
#                     free: "",
#                     caption: "",
#                     spine: "",
#                     cslocation: "#{val["location"]["code"]} #{val["rmc"]['Vault location']}",
#                     code: "#{val['location']["code"]}",
#                     callnumber: "#{val["call"]}",
#                     Restrictions: "#{restrictions}"

# e.g., for http://localhost:9292/aeon/reading_room_request/5418772 (Ezra Cornell Papers)

# <div><labelfor='31924088371251'class='sr-only'>31924088371251</label><inputclass='ItemNo'id='31924088371251'name='31924088371251'type='checkbox'VALUE='31924088371251'>(RequestinAdvance)2-12-3411c.1box1</div><script>itemdata[
#   "31924088371251"
# ]={
#   location: "ANNEX",
#   enumeration: "box 1",
#   barcode: "31924088371251",
#   loc_code: "rmc,anx",
#   chron: "",
#   copy: "1",
#   free: "",
#   caption: "",
#   spine: "",
#   cslocation: "ANNEX",
#   code: "rmc,anx",
#   callnumber: "2-12-3411",
#   Restrictions: ""
# };</script>
# <div><labelfor='iid-7d386b81-8b13-4cc3-bfd9-c95a3a8665e6'class='sr-only'>iid-7d386b81-8b13-4cc3-bfd9-c95a3a8665e6</label><inputclass='ItemNo'id='iid-7d386b81-8b13-4cc3-bfd9-c95a3a8665e6'name='iid-7d386b81-8b13-4cc3-bfd9-c95a3a8665e6'type='checkbox'VALUE='iid-7d386b81-8b13-4cc3-bfd9-c95a3a8665e6'>(AvailableImmediately)2-12-3411c.1f?</div><script>itemdata[
#   "iid-7d386b81-8b13-4cc3-bfd9-c95a3a8665e6"
# ]={
#   location: "K-249-F-8",
#   enumeration: "f ?",
#   barcode: "iid-7d386b81-8b13-4cc3-bfd9-c95a3a8665e6",
#   loc_code: "rmc",
#   chron: "",
#   copy: "1",
#   free: "",
#   caption: "",
#   spine: "",
#   cslocation: "rmc K-249-F-8",
#   code: "rmc",
#   callnumber: "2-12-3411",
#   Restrictions: ""
# };</script><!--Producing menu with items no need to refetch data. ic=**$ic**\n -->