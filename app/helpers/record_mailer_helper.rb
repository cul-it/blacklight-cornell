module RecordMailerHelper
  
  # Truncate title for SMS text to conform to 140-character (8-bit character) limit
  # Assumes @location, @callnumber, @tiny are supplied to the view
  def truncate_title(doc)
    other_length = 0
    other_length += "FRM:culsearch@cornell.edu".length
    other_length += @location.length if @location
    other_length += @callnumber.length if @callnumber
    other_length += @tiny.length if @tiny
    other_length += 8 # padding
    
    if (doc.length + other_length > 140)
      doc[0..140-other_length] + '...'
    else
      doc
    end
    
  end
  
end