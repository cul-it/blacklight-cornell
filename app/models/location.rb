class Location < ActiveRecord::Base

  def self.aeon_eligible?(code)
    return where("code = ?", code).first.rmc_aeon 
  end

  def aeon_eligible?(code)
    return where("code = ?", code).rmc_aeon 
  end
end
