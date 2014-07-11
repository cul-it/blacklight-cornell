client = Savon.client(wsdl: 'http://rmws.serialssolutions.com/serialssolutionswebservice/SerialsSolutions360WebService.asmx?wsdl') do convert_request_keys_to :none end
response = client.call(:license_data, message: { request: {op: 'LicenseData', UserName: 'esubs-l@cornell.edu', Password: 'terms4USE', LibraryCode: 'COO'}})
docResponse = Nokogiri.XML(response.to_s) do |config|
 config.default_xml.noblanks
end

File.open("licenseData.xml", 'w') { |file| file.write(docResponse.to_xml) }
#puts docResponse.to_xml(:indent => 2)
File.close

