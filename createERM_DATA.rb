require 'nokogiri'

class Parser 

  attr_accessor :doc

  def initialize(filename)
    file = File.open(filename, "r")
    @doc = Nokogiri::XML(file)
  end

  def getChildNodeContents(parentNode, childNode)
    parentNode.xpath(sprintf('./%s',childNode)).each do |node|
      return node.content 
    end
  end

  def getNode(parentNode)
    return parentNode.xpath()
  end

  def parseRecords(tagname)
     count = 0
     puts "in parse Records\n"
     label = @doc.xpath(sprintf('//%s','Label'))
    @doc.xpath(sprintf('//%s',tagname)).each do |record|
      puts record.values
      count = count + 1
      puts count
    end
  end
end
data = Parser.new("licenseData.xml")
data.parseRecords("License")

