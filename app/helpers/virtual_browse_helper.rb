# Helper methods for the advanced search form
module VirtualBrowseHelper
  
  def get_format_string(format)
    fa_string = ""
    if format.include?("journal")
      fa_string =  '<i class="fa fa-book-open"></i>'
    elsif format.include?("book")
      fa_string =  '<i class="fa fa-book"></i>'
    elsif format.include?("microform")
      fa_string =  '<i class="fa fa-film"></i>'
    elsif format.include?("non-musical")
      fa_string =  '<i class="fa fa-headphones"></i>'
    elsif format.include?("musical score")
      fa_string =  '<i class="fa fa-musical-score"></i>'
    elsif format.include?("musical")
      fa_string =  '<i class="fa fa-music"></i>'
    elsif format.include?("thesis")
      fa_string =  '<i class="fa fa-file-text-o"></i>'
    elsif format.include?("video")
      fa_string =  '<i class="fa fa-video-camera"></i>'
    elsif format.include?("manuscript")
      fa_string =  '<i class="fa fa-archive"></i>'
    elsif format.include?("map")
      fa_string = '<i class="fa fa-globe"></i>'
    end
    return fa_string.html_safe
  end

end
