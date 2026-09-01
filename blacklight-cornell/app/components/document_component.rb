class DocumentComponent < Blacklight::DocumentComponent
  def online_data
    helpers.is_online?(@document) ? "data-online='no'" : "data-online='no'"
  end

  def atl_data
    is_at_the_library? ? "data-atl='yes'" : "data-atl='no'"
  end

  def is_at_the_library?
    @document['online'].present? && @document['online'].include?('At the Library')
  end
end
