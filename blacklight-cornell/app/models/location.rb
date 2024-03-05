class Location < ActiveRecord::Base
  attr_accessible :code,:voyager_id,:display_name,:hours_page,:rmc_aeon


  def self.help_page(code)
   base_url = 'https://www.library.cornell.edu/libraries/'
   code.delete!(' ')
    rec = where("code = ?", code).first
    rec ?  rec.hours_page  : base_url
    location_url =
      case
        when rec && rec.hours_page.present? && rec.hours_page.include?('http:')
          rec.hours_page
        when rec && rec.hours_page.present? && !rec.hours_page.include?('http:')
          base_url + rec.hours_page
        else
          base_url
     end
    location_url 
  end

  def self.aeon_eligible?(code)
    ret = false 
    code.delete!(' ')
    rec = where("code = ?", code).first
    rec ?  rec.rmc_aeon : ret
  end

  def aeon_eligible?(code)
    code.delete!(' ')
    return where("code = ?", code).rmc_aeon 
  end
end
