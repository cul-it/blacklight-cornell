module ApplicationHelper
#  include Blacklight::SolrHelper
#  include Blacklight::Catalog
    
  def alternating_line(id="default")
    @alternating_line ||= Hash.new("odd")
    @alternating_line[id] = @alternating_line[id] == "even" ? "odd" : "even"
  end


end
