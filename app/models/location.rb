class Location < ActiveRecord::Base

  def self.aeon_eligible?(code)
    ret = false 
    rec = where("code = ?", code).first
    rec ?  rec.rmc_aeon : ret
  end

  def aeon_eligible?(code)
    return where("code = ?", code).rmc_aeon 
  end
end
