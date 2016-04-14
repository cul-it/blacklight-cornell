xml.instruct!
xml.formats(({:id => @document.id} if @document) || {}) do
  @export_formats.each do |shortname, meta|
    if shortname.to_s == 'marc' 
      xml.format :name => "whatever" , :type => "whatever/whatever" 
    else 
      xml.format :name => shortname, :type => meta[:content_type]
    end
  end
end
