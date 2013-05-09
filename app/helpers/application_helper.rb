module ApplicationHelper
#  include Blacklight::SolrHelper
#  include Blacklight::Catalog
    
  def alternating_line(id="default")
    @alternating_line ||= Hash.new("odd")
    @alternating_line[id] = @alternating_line[id] == "even" ? "odd" : "even"
  end

  def link_to_previous_bookmark(previous_bookmark, counter)
    link_to_unless previous_bookmark.nil?, raw(t('views.pagination.previous')), previous_bookmark, :class => "previous", :rel => 'prev', :'data-counter' => counter - 1 do
      content_tag :span, raw(t('views.pagination.previous')), :class => 'previous'
    end
  end

  def link_to_next_bookmark(next_bookmark, counter)
    link_to_unless next_bookmark.nil?, raw(t('views.pagination.next')), next_bookmark, :class => "next", :rel => 'next', :'data-counter' => counter + 1 do
      content_tag :span, raw(t('views.pagination.next')), :class => 'next'
    end
  end


end
