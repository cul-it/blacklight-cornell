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

  def link_to_document(doc, opts={:label=>nil, :counter => nil, :results_view => true})
    opts[:label] ||= blacklight_config.index.show_link.to_sym
    label = render_document_index_label doc, opts
    if params[:controller] == 'bookmarks'
      docID = doc.id
      link_to label, '/catalog/' + docID #, { :'data-counter' => opts[:counter] }.merge(opts.reject { |k,v| [:label, :counter, :results_view].include? k  })
    else
      link_to label, doc, { :'data-counter' => opts[:counter] }.merge(opts.reject { |k,v| [:label, :counter, :results_view].include? k  })
    end
  end


end
