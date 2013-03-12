class Aeon

 AEON_SITES  = [
  'rmc' ,
  'rmc,anx',
  'rmc,icer',
  'rmc,hsci',
  'was,rare',
  'was,ranx',
  'ech,rare',
  'ech,ranx',
  'sasa,rare',
  'sasa,ranx',
  'hote,rare' 
  ]

 AEON_CODES  = [
  '87' ,
  '203',
  '121',
  '48',
  '143',
  '234',
	 '17', 
	'233',
	'126', 
	'232',
	 '45' 
  ]

  def self.eligible?(lib)
    return AEON_SITES.include?(lib) 
  end 

  def self.eligible_id?(lib)
    return AEON_CODES.include?(lib) 
  end 

end
