# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Location.create("voyager_id"=>2, "code"=>"afr", "display_name"=>"Africana Library (Africana Center)", "hours_page"=>"afr", "rmc_aeon"=>false)
Location.create("voyager_id"=>3, "code"=>"afr,anx", "display_name"=>"Library Annex", "hours_page"=>"afr_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>4, "code"=>"afr,res", "display_name"=>"Africana Library Reserve", "hours_page"=>"afr_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>5, "code"=>"afr,ref", "display_name"=>"Africana Library Reference ( Non-Circulating)", "hours_page"=>"afr_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>6, "code"=>"agen", "display_name"=>"Ag Engineering Library (Riley Robb Hall) (Dept. use only)", "hours_page"=>"agen", "rmc_aeon"=>false)
Location.create("voyager_id"=>8, "code"=>"bioc", "display_name"=>"Biochem Reading Room (Biotech Building) (Dept. use only)", "hours_page"=>"bioc", "rmc_aeon"=>false)
Location.create("voyager_id"=>9, "code"=>"cise", "display_name"=>"CISER Data Archive", "hours_page"=>"cise", "rmc_aeon"=>false)
Location.create("voyager_id"=>10, "code"=>"cons", "display_name"=>"Preservation Department (B32 Olin)", "hours_page"=>"cons", "rmc_aeon"=>false)
Location.create("voyager_id"=>11, "code"=>"cons,lab", "display_name"=>"Conservation Laboratory (Library Annex)", "hours_page"=>"cons_lab", "rmc_aeon"=>false)
Location.create("voyager_id"=>12, "code"=>"cons,opt", "display_name"=>"", "hours_page"=>"cons_opt", "rmc_aeon"=>false)
Location.create("voyager_id"=>13, "code"=>"ech", "display_name"=>"Kroch Library Asia", "hours_page"=>"ech", "rmc_aeon"=>false)
Location.create("voyager_id"=>14, "code"=>"ech,anx", "display_name"=>"Library Annex", "hours_page"=>"ech_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>15, "code"=>"ech,av", "display_name"=>"Uris Library Asia A/V", "hours_page"=>"ech_av", "rmc_aeon"=>false)
Location.create("voyager_id"=>16, "code"=>"ech,str1", "display_name"=>"Request at Olin Circulation Desk", "hours_page"=>"ech_str1", "rmc_aeon"=>false)
Location.create("voyager_id"=>17, "code"=>"ech,rare", "display_name"=>"Kroch Library Rare & Manuscripts (Non-Circulating)", "hours_page"=>"ech_rare", "rmc_aeon"=>true)
Location.create("voyager_id"=>18, "code"=>"ech,ref", "display_name"=>"Kroch Library Asia Reference (Non-Circulating)", "hours_page"=>"ech_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>19, "code"=>"engr", "display_name"=>"Library Annex", "hours_page"=>"engr", "rmc_aeon"=>false)
Location.create("voyager_id"=>20, "code"=>"engr,ref", "display_name"=>"Library Annex", "hours_page"=>"engr_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>21, "code"=>"engr,anx", "display_name"=>"Library Annex", "hours_page"=>"engr_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>22, "code"=>"engr,base", "display_name"=>"Library Annex", "hours_page"=>"engr_base", "rmc_aeon"=>false)
Location.create("voyager_id"=>23, "code"=>"engr,res", "display_name"=>"Library Annex", "hours_page"=>"engr_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>24, "code"=>"engr,wpe", "display_name"=>"Library Annex", "hours_page"=>"engr_wpe", "rmc_aeon"=>false)
Location.create("voyager_id"=>25, "code"=>"ent", "display_name"=>"Mann Library New Book Shelf", "hours_page"=>"ent", "rmc_aeon"=>false)
Location.create("voyager_id"=>26, "code"=>"ent,anx", "display_name"=>"Library Annex", "hours_page"=>"ent_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>27, "code"=>"ent,rar2", "display_name"=>"Entomology Library Rare (Non-Circulating)", "hours_page"=>"ent_rar2", "rmc_aeon"=>false)
Location.create("voyager_id"=>28, "code"=>"ent,rare", "display_name"=>"Entomology Library Rare (Non-Circulating)", "hours_page"=>"ent_rare", "rmc_aeon"=>false)
Location.create("voyager_id"=>29, "code"=>"ent,res", "display_name"=>"Entomology Library Reserve", "hours_page"=>"ent_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>30, "code"=>"ent,ref", "display_name"=>"Entomology Library Reference (Non-Circulating)", "hours_page"=>"ent_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>31, "code"=>"fine", "display_name"=>"Fine Arts Library (Rand Hall)", "hours_page"=>"fine", "rmc_aeon"=>false)
Location.create("voyager_id"=>32, "code"=>"fine,anx", "display_name"=>"Library Annex", "hours_page"=>"fine_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>33, "code"=>"fine,res", "display_name"=>"Fine Arts Library Reserve", "hours_page"=>"fine_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>34, "code"=>"fine,lock", "display_name"=>"Fine Arts Library (Ask at Circulation)", "hours_page"=>"fine_lock", "rmc_aeon"=>false)
Location.create("voyager_id"=>35, "code"=>"fine,nine", "display_name"=>"Fine Arts Library (Ask at Circulation)", "hours_page"=>"fine_nine", "rmc_aeon"=>false)
Location.create("voyager_id"=>36, "code"=>"fine,ref", "display_name"=>"Fine Arts Library Reference (Non-Circulating)", "hours_page"=>"fine_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>37, "code"=>"food", "display_name"=>"Food Science Library (Stocking Hall) (Dept. use only)", "hours_page"=>"food", "rmc_aeon"=>false)
Location.create("voyager_id"=>38, "code"=>"gnva", "display_name"=>"Library Annex", "hours_page"=>"gnva", "rmc_aeon"=>false)
Location.create("voyager_id"=>39, "code"=>"gnva,anx", "display_name"=>"Library Annex", "hours_page"=>"gnva_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>40, "code"=>"gnva,rare", "display_name"=>"Mann Library Special Collections (Non-Circulating)", "hours_page"=>"gnva_rare", "rmc_aeon"=>false)
Location.create("voyager_id"=>41, "code"=>"gnva,ref", "display_name"=>"Library Annex", "hours_page"=>"gnva_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>43, "code"=>"hote", "display_name"=>"ILR Library (Ives Hall)", "hours_page"=>"hote", "rmc_aeon"=>false)
Location.create("voyager_id"=>44, "code"=>"hote,anx", "display_name"=>"Library Annex", "hours_page"=>"hote_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>45, "code"=>"hote,rare", "display_name"=>"Kroch Library Rare & Manuscripts (Non-Circulating)", "hours_page"=>"hote_rare", "rmc_aeon"=>true)
Location.create("voyager_id"=>46, "code"=>"hote,ref", "display_name"=>"ILR Library Reference (Non-Circulating)", "hours_page"=>"hote_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>47, "code"=>"hote,res", "display_name"=>"Nestle Library Reserve", "hours_page"=>"hote_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>48, "code"=>"rmc,hsci", "display_name"=>"Kroch Library Rare & Manuscripts (Non-Circulating)", "hours_page"=>"rmc_hsci", "rmc_aeon"=>true)
Location.create("voyager_id"=>49, "code"=>"rmc,ref", "display_name"=>"Kroch Library Rare & Manuscripts Reference (Non-Circulating)", "hours_page"=>"rmc_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>50, "code"=>"rmc,ice", "display_name"=>"Olin Library", "hours_page"=>"rmc_ice", "rmc_aeon"=>false)
Location.create("voyager_id"=>51, "code"=>"ilr", "display_name"=>"ILR Library (Ives Hall)", "hours_page"=>"ilr", "rmc_aeon"=>false)
Location.create("voyager_id"=>52, "code"=>"ilr,anx", "display_name"=>"Library Annex", "hours_page"=>"ilr_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>53, "code"=>"ilr,ref", "display_name"=>"ILR Library Reference (Non-Circulating)", "hours_page"=>"ilr_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>54, "code"=>"ilr,kanx", "display_name"=>"ILR Library Kheel Center (Request in advance)", "hours_page"=>"ilr_kanx", "rmc_aeon"=>false)
Location.create("voyager_id"=>55, "code"=>"ilr,lmdc", "display_name"=>"ILR Library Kheel Center", "hours_page"=>"ilr_lmdc", "rmc_aeon"=>false)
Location.create("voyager_id"=>56, "code"=>"ilr,lmdr", "display_name"=>"ILR Library Kheel Center Reference", "hours_page"=>"ilr_lmdr", "rmc_aeon"=>false)
Location.create("voyager_id"=>57, "code"=>"ilr,rare", "display_name"=>"ILR Library Kheel Center", "hours_page"=>"ilr_rare", "rmc_aeon"=>false)
Location.create("voyager_id"=>58, "code"=>"ilr,res", "display_name"=>"ILR Library Reserve", "hours_page"=>"ilr_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>59, "code"=>"jgsm", "display_name"=>"ILR Library (Ives Hall)", "hours_page"=>"jgsm", "rmc_aeon"=>false)
Location.create("voyager_id"=>60, "code"=>"jgsm,anx", "display_name"=>"Library Annex", "hours_page"=>"jgsm_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>61, "code"=>"jgsm,res", "display_name"=>"Sage Hall Management Library Reserve", "hours_page"=>"jgsm_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>62, "code"=>"jgsm,ref", "display_name"=>"ILR Library Reference (Non-Circulating)", "hours_page"=>"jgsm_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>63, "code"=>"law", "display_name"=>"Law Library (Myron Taylor Hall)", "hours_page"=>"law", "rmc_aeon"=>false)
Location.create("voyager_id"=>64, "code"=>"law,anx", "display_name"=>"Library Annex", "hours_page"=>"law_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>65, "code"=>"law,ref", "display_name"=>"Law Library Reference (Non-Circulating)", "hours_page"=>"law_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>66, "code"=>"law,lega", "display_name"=>"Legal Aid Clinic", "hours_page"=>"law_lega", "rmc_aeon"=>false)
Location.create("voyager_id"=>67, "code"=>"law,res", "display_name"=>"Law Library Reserve", "hours_page"=>"law_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>68, "code"=>"law,ts", "display_name"=>"Law Library Technical Services", "hours_page"=>"law_ts", "rmc_aeon"=>false)
Location.create("voyager_id"=>69, "code"=>"mann", "display_name"=>"Mann Library", "hours_page"=>"mann", "rmc_aeon"=>false)
Location.create("voyager_id"=>70, "code"=>"mann,ts", "display_name"=>"Mann Library Technical Services (Non-Circulating)", "hours_page"=>"mann_ts", "rmc_aeon"=>false)
Location.create("voyager_id"=>71, "code"=>"mann,anx", "display_name"=>"Library Annex", "hours_page"=>"mann_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>72, "code"=>"mann,anxt", "display_name"=>"Library Annex", "hours_page"=>"mann_anxt", "rmc_aeon"=>false)
Location.create("voyager_id"=>73, "code"=>"mann,spec", "display_name"=>"Mann Library Special Collections (Non-Circulating)", "hours_page"=>"mann_spec", "rmc_aeon"=>false)
Location.create("voyager_id"=>74, "code"=>"mann,cd", "display_name"=>"Mann Library Collection Development (Non-Circulating)", "hours_page"=>"mann_cd", "rmc_aeon"=>false)
Location.create("voyager_id"=>75, "code"=>"mann,ref", "display_name"=>"Mann Library Reference (Non-Circulating)", "hours_page"=>"mann_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>76, "code"=>"mann,gate", "display_name"=>"Networked Resource", "hours_page"=>"mann_gate", "rmc_aeon"=>false)
Location.create("voyager_id"=>77, "code"=>"mann,hort", "display_name"=>"Bailey Hortorium (ask at Mann Library Circulation)", "hours_page"=>"mann_hort", "rmc_aeon"=>false)
Location.create("voyager_id"=>78, "code"=>"mann,href", "display_name"=>"Bailey Hortorium Reference (Non-Circulating)", "hours_page"=>"mann_href", "rmc_aeon"=>false)
Location.create("voyager_id"=>79, "code"=>"mann,res", "display_name"=>"Mann Library Reserve", "hours_page"=>"mann_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>80, "code"=>"maps", "display_name"=>"Olin Library Maps (Non-Circulating)", "hours_page"=>"maps", "rmc_aeon"=>false)
Location.create("voyager_id"=>81, "code"=>"math", "display_name"=>"Mathematics Library (Malott Hall)", "hours_page"=>"math", "rmc_aeon"=>false)
Location.create("voyager_id"=>82, "code"=>"math,anx", "display_name"=>"Library Annex", "hours_page"=>"math_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>83, "code"=>"math,desk", "display_name"=>"Mathematics Library (Circulation Desk)", "hours_page"=>"math_desk", "rmc_aeon"=>false)
Location.create("voyager_id"=>84, "code"=>"math,ref", "display_name"=>"Mathematics Library Reference (Non-Circulating)", "hours_page"=>"math_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>85, "code"=>"math,lock", "display_name"=>"Mathematics Library Locked Press", "hours_page"=>"math_lock", "rmc_aeon"=>false)
Location.create("voyager_id"=>86, "code"=>"math,res", "display_name"=>"Mathematics Library Reserve", "hours_page"=>"math_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>87, "code"=>"rmc", "display_name"=>"Kroch Library Rare & Manuscripts (Non-Circulating)", "hours_page"=>"rmc", "rmc_aeon"=>true)
Location.create("voyager_id"=>88, "code"=>"mus", "display_name"=>"Cox Library of Music (Lincoln Hall)", "hours_page"=>"mus", "rmc_aeon"=>false)
Location.create("voyager_id"=>89, "code"=>"mus,anx", "display_name"=>"Library Annex", "hours_page"=>"mus_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>90, "code"=>"mus,av", "display_name"=>"Music Library A/V (Non-Circulating)", "hours_page"=>"mus_av", "rmc_aeon"=>false)
Location.create("voyager_id"=>91, "code"=>"mus,lock", "display_name"=>"Music Library Locked Press (Reference Desk)", "hours_page"=>"mus_lock", "rmc_aeon"=>false)
Location.create("voyager_id"=>92, "code"=>"mus,res", "display_name"=>"Music Library Reserve", "hours_page"=>"mus_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>93, "code"=>"mus,ref", "display_name"=>"Music Library Reference (Non-Circulating)", "hours_page"=>"mus_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>94, "code"=>"nus", "display_name"=>"", "hours_page"=>"nus", "rmc_aeon"=>false)
Location.create("voyager_id"=>95, "code"=>"oclc,afrp", "display_name"=>"Africana Library Reserve", "hours_page"=>"oclc_afrp", "rmc_aeon"=>false)
Location.create("voyager_id"=>96, "code"=>"oclc,echm", "display_name"=>"Kroch Library Asia", "hours_page"=>"oclc_echm", "rmc_aeon"=>false)
Location.create("voyager_id"=>97, "code"=>"oclc,olim", "display_name"=>"Olin Library", "hours_page"=>"oclc_olim", "rmc_aeon"=>false)
Location.create("voyager_id"=>98, "code"=>"oclc,olir", "display_name"=>"Olin Library Reference (Non-Circulating)", "hours_page"=>"oclc_olir", "rmc_aeon"=>false)
Location.create("voyager_id"=>99, "code"=>"olin", "display_name"=>"Olin Library", "hours_page"=>"olin", "rmc_aeon"=>false)
Location.create("voyager_id"=>100, "code"=>"cts", "display_name"=>"", "hours_page"=>"cts", "rmc_aeon"=>false)
Location.create("voyager_id"=>101, "code"=>"olin,anx", "display_name"=>"Library Annex", "hours_page"=>"olin_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>102, "code"=>"olin,str1", "display_name"=>"Request at Olin Circulation Desk", "hours_page"=>"olin_str1", "rmc_aeon"=>false)
Location.create("voyager_id"=>103, "code"=>"olin,ref", "display_name"=>"Olin Library Reference (Non-Circulating)", "hours_page"=>"olin_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>104, "code"=>"olin,605", "display_name"=>"Olin Library Room 604-605 (Non-Circulating)", "hours_page"=>"olin_605", "rmc_aeon"=>false)
Location.create("voyager_id"=>105, "code"=>"olin,301", "display_name"=>"Olin Library Room 301 (Non-Circulating)", "hours_page"=>"olin_301", "rmc_aeon"=>false)
Location.create("voyager_id"=>106, "code"=>"olin,305", "display_name"=>"Olin Library Room 305 (Non-Circulating)", "hours_page"=>"olin_305", "rmc_aeon"=>false)
Location.create("voyager_id"=>107, "code"=>"olin,401", "display_name"=>"Olin Library Room 401 (Non-Circulating)", "hours_page"=>"olin_401", "rmc_aeon"=>false)
Location.create("voyager_id"=>108, "code"=>"olin,404", "display_name"=>"Olin Library Room 404 (Non-Circulating)", "hours_page"=>"olin_404", "rmc_aeon"=>false)
Location.create("voyager_id"=>109, "code"=>"olin,405", "display_name"=>"Olin Library Room 405 (Non-Circulating)", "hours_page"=>"olin_405", "rmc_aeon"=>false)
Location.create("voyager_id"=>110, "code"=>"olin,601", "display_name"=>"Olin Library Room 601 (Non-Circulating)", "hours_page"=>"olin_601", "rmc_aeon"=>false)
Location.create("voyager_id"=>111, "code"=>"olin,604", "display_name"=>"Olin Library Room 604-605 (Non-Circulating)", "hours_page"=>"olin_604", "rmc_aeon"=>false)
Location.create("voyager_id"=>112, "code"=>"olin,str2", "display_name"=>"Special Location -- Ask at Olin Circulation Desk", "hours_page"=>"olin_str2", "rmc_aeon"=>false)
Location.create("voyager_id"=>113, "code"=>"orni", "display_name"=>"Adelson Library (Lab of Ornithology)", "hours_page"=>"orni", "rmc_aeon"=>false)
Location.create("voyager_id"=>114, "code"=>"orni,ref", "display_name"=>"Adelson Library Reference (Lab of Ornithology)", "hours_page"=>"orni_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>115, "code"=>"phys", "display_name"=>"Spacecraft Planetary Imaging Facility (Non-Circulating)", "hours_page"=>"phys", "rmc_aeon"=>false)
Location.create("voyager_id"=>116, "code"=>"phys,anx", "display_name"=>"Library Annex", "hours_page"=>"phys_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>117, "code"=>"phys,ref", "display_name"=>"Physical Sciences Library Reference (Non-Circulating)", "hours_page"=>"phys_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>119, "code"=>"phys,res", "display_name"=>"Physical Sciences Reserve", "hours_page"=>"phys_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>120, "code"=>"cts,rev", "display_name"=>"Library Technical Services Review Shelves", "hours_page"=>"cts_rev", "rmc_aeon"=>false)
Location.create("voyager_id"=>121, "code"=>"rmc,icer", "display_name"=>"Kroch Library Rare & Manuscripts (Non-Circulating)", "hours_page"=>"rmc_icer", "rmc_aeon"=>true)
Location.create("voyager_id"=>122, "code"=>"sasa", "display_name"=>"Kroch Library Asia", "hours_page"=>"sasa", "rmc_aeon"=>false)
Location.create("voyager_id"=>123, "code"=>"sasa,anx", "display_name"=>"Library Annex", "hours_page"=>"sasa_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>124, "code"=>"sasa,av", "display_name"=>"Uris Library Asia A/V", "hours_page"=>"sasa_av", "rmc_aeon"=>false)
Location.create("voyager_id"=>125, "code"=>"sasa,str1", "display_name"=>"Request at Olin Circulation Desk", "hours_page"=>"sasa_str1", "rmc_aeon"=>false)
Location.create("voyager_id"=>126, "code"=>"sasa,rare", "display_name"=>"Kroch Library Rare & Manuscripts (Non-Circulating)", "hours_page"=>"sasa_rare", "rmc_aeon"=>true)
Location.create("voyager_id"=>127, "code"=>"sasa,ref", "display_name"=>"Kroch Library Asia Reference (Non-Circulating)", "hours_page"=>"sasa_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>128, "code"=>"serv,remo", "display_name"=>"*Networked Resource", "hours_page"=>"serv_remo", "rmc_aeon"=>false)
Location.create("voyager_id"=>129, "code"=>"uris", "display_name"=>"Uris Library", "hours_page"=>"uris", "rmc_aeon"=>false)
Location.create("voyager_id"=>130, "code"=>"uris,res2", "display_name"=>"Uris Library Reserve Willis Room", "hours_page"=>"uris_res2", "rmc_aeon"=>false)
Location.create("voyager_id"=>131, "code"=>"uris,ref", "display_name"=>"Uris Library Reference (Non-Circulating)", "hours_page"=>"uris_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>132, "code"=>"uris,res", "display_name"=>"Uris Library Reserve", "hours_page"=>"uris_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>133, "code"=>"vet", "display_name"=>"Veterinary Library (Schurman Hall)", "hours_page"=>"vet", "rmc_aeon"=>false)
Location.create("voyager_id"=>134, "code"=>"vet,anx", "display_name"=>"Library Annex", "hours_page"=>"vet_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>135, "code"=>"vet,core", "display_name"=>"Veterinary Library Core Resource (Non-Circulating)", "hours_page"=>"vet_core", "rmc_aeon"=>false)
Location.create("voyager_id"=>136, "code"=>"vet,res", "display_name"=>"Veterinary Library Reserve", "hours_page"=>"vet_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>137, "code"=>"vet,rare", "display_name"=>"Veterinary Library Rare Books (Non-Circulating)", "hours_page"=>"vet_rare", "rmc_aeon"=>false)
Location.create("voyager_id"=>138, "code"=>"vet,ref", "display_name"=>"Veterinary Library Reference (Non-Circulating)", "hours_page"=>"vet_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>139, "code"=>"was", "display_name"=>"Kroch Library Asia", "hours_page"=>"was", "rmc_aeon"=>false)
Location.create("voyager_id"=>140, "code"=>"was,anx", "display_name"=>"Library Annex", "hours_page"=>"was_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>141, "code"=>"was,av", "display_name"=>"Uris Library Asia A/V", "hours_page"=>"was_av", "rmc_aeon"=>false)
Location.create("voyager_id"=>142, "code"=>"was,str1", "display_name"=>"Request at Olin Circulation Desk", "hours_page"=>"was_str1", "rmc_aeon"=>false)
Location.create("voyager_id"=>143, "code"=>"was,rare", "display_name"=>"Kroch Library Rare & Manuscripts (Non-Circulating)", "hours_page"=>"was_rare", "rmc_aeon"=>true)
Location.create("voyager_id"=>144, "code"=>"was,ref", "display_name"=>"Kroch Library Asia Reference (Non-Circulating)", "hours_page"=>"was_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>147, "code"=>"ilr,mcs", "display_name"=>"ILR Multi-Copy Storage", "hours_page"=>"ilr_mcs", "rmc_aeon"=>false)
Location.create("voyager_id"=>149, "code"=>"afr,circ", "display_name"=>"", "hours_page"=>"afr_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>150, "code"=>"afr,proc", "display_name"=>"", "hours_page"=>"afr_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>151, "code"=>"anx,circ", "display_name"=>"", "hours_page"=>"anx_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>152, "code"=>"ech,proc", "display_name"=>"", "hours_page"=>"ech_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>153, "code"=>"cts,acq", "display_name"=>"", "hours_page"=>"cts_acq", "rmc_aeon"=>false)
Location.create("voyager_id"=>154, "code"=>"cts,appr", "display_name"=>"", "hours_page"=>"cts_appr", "rmc_aeon"=>false)
Location.create("voyager_id"=>155, "code"=>"cts,doc", "display_name"=>"", "hours_page"=>"cts_doc", "rmc_aeon"=>false)
Location.create("voyager_id"=>156, "code"=>"cts,sto", "display_name"=>"", "hours_page"=>"cts_sto", "rmc_aeon"=>false)
Location.create("voyager_id"=>157, "code"=>"engr,circ", "display_name"=>"", "hours_page"=>"engr_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>158, "code"=>"engr,proc", "display_name"=>"", "hours_page"=>"engr_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>159, "code"=>"ent,circ", "display_name"=>"", "hours_page"=>"ent_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>160, "code"=>"fine,circ", "display_name"=>"", "hours_page"=>"fine_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>161, "code"=>"fine,proc", "display_name"=>"", "hours_page"=>"fine_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>162, "code"=>"gnva,circ", "display_name"=>"", "hours_page"=>"gnva_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>163, "code"=>"gnva,proc", "display_name"=>"", "hours_page"=>"gnva_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>164, "code"=>"gift,exch", "display_name"=>"", "hours_page"=>"gift_exch", "rmc_aeon"=>false)
Location.create("voyager_id"=>165, "code"=>"hote,circ", "display_name"=>"", "hours_page"=>"hote_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>166, "code"=>"hote,proc", "display_name"=>"", "hours_page"=>"hote_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>167, "code"=>"ilr,circ", "display_name"=>"", "hours_page"=>"ilr_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>168, "code"=>"ilr,ts", "display_name"=>"Library Annex", "hours_page"=>"ilr_ts", "rmc_aeon"=>false)
Location.create("voyager_id"=>169, "code"=>"jgsm,circ", "display_name"=>"", "hours_page"=>"jgsm_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>170, "code"=>"jgsm,proc", "display_name"=>"Library Annex", "hours_page"=>"jgsm_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>171, "code"=>"law,circ", "display_name"=>"", "hours_page"=>"law_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>172, "code"=>"mann,circ", "display_name"=>"", "hours_page"=>"mann_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>173, "code"=>"mann,doc", "display_name"=>"Library Annex", "hours_page"=>"mann_doc", "rmc_aeon"=>false)
Location.create("voyager_id"=>174, "code"=>"mann,ser", "display_name"=>"", "hours_page"=>"mann_ser", "rmc_aeon"=>false)
Location.create("voyager_id"=>175, "code"=>"maps,proc", "display_name"=>"", "hours_page"=>"maps_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>176, "code"=>"math,circ", "display_name"=>"", "hours_page"=>"math_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>177, "code"=>"math,proc", "display_name"=>"", "hours_page"=>"math_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>178, "code"=>"mus,ts", "display_name"=>"Library Annex", "hours_page"=>"mus_ts", "rmc_aeon"=>false)
Location.create("voyager_id"=>179, "code"=>"mus,circ", "display_name"=>"", "hours_page"=>"mus_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>180, "code"=>"mann,ils", "display_name"=>"", "hours_page"=>"mann_ils", "rmc_aeon"=>false)
Location.create("voyager_id"=>181, "code"=>"olin,circ", "display_name"=>"", "hours_page"=>"olin_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>182, "code"=>"olin,ils", "display_name"=>"", "hours_page"=>"olin_ils", "rmc_aeon"=>false)
Location.create("voyager_id"=>183, "code"=>"oku,proc", "display_name"=>"", "hours_page"=>"oku_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>184, "code"=>"phys,circ", "display_name"=>"", "hours_page"=>"phys_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>185, "code"=>"phys,proc", "display_name"=>"", "hours_page"=>"phys_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>186, "code"=>"rmc,circ", "display_name"=>"", "hours_page"=>"rmc_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>187, "code"=>"rmc,ts", "display_name"=>"", "hours_page"=>"rmc_ts", "rmc_aeon"=>false)
Location.create("voyager_id"=>188, "code"=>"uris,circ", "display_name"=>"", "hours_page"=>"uris_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>189, "code"=>"vet,circ", "display_name"=>"", "hours_page"=>"vet_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>190, "code"=>"vet,proc", "display_name"=>"", "hours_page"=>"vet_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>191, "code"=>"was,proc", "display_name"=>"", "hours_page"=>"was_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>192, "code"=>"bind,circ", "display_name"=>"", "hours_page"=>"bind_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>193, "code"=>"acct,endw", "display_name"=>"", "hours_page"=>"acct_endw", "rmc_aeon"=>false)
Location.create("voyager_id"=>194, "code"=>"acct,mann", "display_name"=>"", "hours_page"=>"acct_mann", "rmc_aeon"=>false)
Location.create("voyager_id"=>195, "code"=>"acct,ilr", "display_name"=>"", "hours_page"=>"acct_ilr", "rmc_aeon"=>false)
Location.create("voyager_id"=>196, "code"=>"acct,gnva", "display_name"=>"", "hours_page"=>"acct_gnva", "rmc_aeon"=>false)
Location.create("voyager_id"=>197, "code"=>"acct,hote", "display_name"=>"", "hours_page"=>"acct_hote", "rmc_aeon"=>false)
Location.create("voyager_id"=>198, "code"=>"acct,vet", "display_name"=>"", "hours_page"=>"acct_vet", "rmc_aeon"=>false)
Location.create("voyager_id"=>199, "code"=>"cts,ser", "display_name"=>"", "hours_page"=>"cts_ser", "rmc_aeon"=>false)
Location.create("voyager_id"=>200, "code"=>"AA", "display_name"=>"", "hours_page"=>"AA", "rmc_aeon"=>false)
Location.create("voyager_id"=>201, "code"=>"dum,ord", "display_name"=>"", "hours_page"=>"dum_ord", "rmc_aeon"=>false)
Location.create("voyager_id"=>202, "code"=>"asia,res", "display_name"=>"Asia Reserve, Severinghouse Reading Rm., Kroch Library", "hours_page"=>"asia_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>203, "code"=>"rmc,anx", "display_name"=>"Kroch Library Rare & Manuscripts (Request in advance)", "hours_page"=>"rmc_anx", "rmc_aeon"=>true)
Location.create("voyager_id"=>204, "code"=>"gnva,res", "display_name"=>"Geneva Library Reserve", "hours_page"=>"gnva_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>205, "code"=>"vet,comp", "display_name"=>"Companion Animal Hospital Collection (Departmental use only)", "hours_page"=>"vet_comp", "rmc_aeon"=>false)
Location.create("voyager_id"=>206, "code"=>"vet,equ", "display_name"=>"Equine Farm Animal Collection (Departmental use only)", "hours_page"=>"vet_equ", "rmc_aeon"=>false)
Location.create("voyager_id"=>207, "code"=>"olin,self", "display_name"=>"", "hours_page"=>"olin_self", "rmc_aeon"=>false)
Location.create("voyager_id"=>208, "code"=>"uris,self", "display_name"=>"", "hours_page"=>"uris_self", "rmc_aeon"=>false)
Location.create("voyager_id"=>209, "code"=>"hote,self", "display_name"=>"", "hours_page"=>"hote_self", "rmc_aeon"=>false)
Location.create("voyager_id"=>210, "code"=>"uris,anx", "display_name"=>"Library Annex", "hours_page"=>"uris_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>211, "code"=>"vet,crar", "display_name"=>"Center for Animal Resources and Education (Dept. use only)", "hours_page"=>"vet_crar", "rmc_aeon"=>false)
Location.create("voyager_id"=>212, "code"=>"vet,oph", "display_name"=>"Clinical Ophthalmology Collection (Departmental use only)", "hours_page"=>"vet_oph", "rmc_aeon"=>false)
Location.create("voyager_id"=>213, "code"=>"bd", "display_name"=>"", "hours_page"=>"bd", "rmc_aeon"=>false)
Location.create("voyager_id"=>214, "code"=>"olin,602", "display_name"=>"Olin Library Room 602 (Non-Circulating)", "hours_page"=>"olin_602", "rmc_aeon"=>false)
Location.create("voyager_id"=>215, "code"=>"dcap", "display_name"=>"DCAPS (106G Olin)", "hours_page"=>"dcap", "rmc_aeon"=>false)
Location.create("voyager_id"=>216, "code"=>"olin,av", "display_name"=>"Olin Library", "hours_page"=>"olin_av", "rmc_aeon"=>false)
Location.create("voyager_id"=>217, "code"=>"engr,self", "display_name"=>"", "hours_page"=>"engr_self", "rmc_aeon"=>false)
Location.create("voyager_id"=>218, "code"=>"orni,proc", "display_name"=>"", "hours_page"=>"orni_proc", "rmc_aeon"=>false)
Location.create("voyager_id"=>219, "code"=>"orni,circ", "display_name"=>"", "hours_page"=>"orni_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>220, "code"=>"olin,res", "display_name"=>"Olin Library Reserve", "hours_page"=>"olin_res", "rmc_aeon"=>false)
Location.create("voyager_id"=>221, "code"=>"ilr,ranx", "display_name"=>"Request at ILR Circulation Desk", "hours_page"=>"ilr_ranx", "rmc_aeon"=>false)
Location.create("voyager_id"=>222, "code"=>"orni,cumv", "display_name"=>"Museum of Vertebrates (Lab of Ornithology) (non-circulating)", "hours_page"=>"orni_cumv", "rmc_aeon"=>false)
Location.create("voyager_id"=>223, "code"=>"vet,path", "display_name"=>"Anatomic Pathology Collection (Departmental use only)", "hours_page"=>"vet_path", "rmc_aeon"=>false)
Location.create("voyager_id"=>224, "code"=>"ZZ", "display_name"=>"", "hours_page"=>"ZZ", "rmc_aeon"=>false)
Location.create("voyager_id"=>225, "code"=>"lts,ersm", "display_name"=>"LTS E-Resources and Serials Management", "hours_page"=>"lts_ersm", "rmc_aeon"=>false)
Location.create("voyager_id"=>226, "code"=>"vet,feli", "display_name"=>"Cornell Feline Health Center (Department use only)", "hours_page"=>"vet_feli", "rmc_aeon"=>false)
Location.create("voyager_id"=>227, "code"=>"orni,mac", "display_name"=>"Macaulay Library (Lab of Ornithology) (Non-circulating)", "hours_page"=>"orni_mac", "rmc_aeon"=>false)
Location.create("voyager_id"=>228, "code"=>"YY", "display_name"=>"", "hours_page"=>"YY", "rmc_aeon"=>false)
Location.create("voyager_id"=>229, "code"=>"maps,anx", "display_name"=>"Map Storage (Request in Advance at Map Room, Olin Library)", "hours_page"=>"maps_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>230, "code"=>"maps,circ", "display_name"=>"", "hours_page"=>"maps_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>231, "code"=>"orni,anx", "display_name"=>"Library Annex", "hours_page"=>"orni_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>232, "code"=>"sasa,ranx", "display_name"=>"Kroch Library Rare & Manuscripts (Request in advance)", "hours_page"=>"sasa_ranx", "rmc_aeon"=>true)
Location.create("voyager_id"=>233, "code"=>"ech,ranx", "display_name"=>"Kroch Library Rare & Manuscripts (Request in advance)", "hours_page"=>"ech_ranx", "rmc_aeon"=>true)
Location.create("voyager_id"=>234, "code"=>"was,ranx", "display_name"=>"Kroch Library Rare & Manuscripts (Request in advance)", "hours_page"=>"was_ranx", "rmc_aeon"=>true)
Location.create("voyager_id"=>235, "code"=>"asia", "display_name"=>"Kroch Library Asia", "hours_page"=>"asia", "rmc_aeon"=>false)
Location.create("voyager_id"=>236, "code"=>"asia,anx", "display_name"=>"Library Annex", "hours_page"=>"asia_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>237, "code"=>"asia,av", "display_name"=>"Uris Library Asia A/V", "hours_page"=>"asia_av", "rmc_aeon"=>false)
Location.create("voyager_id"=>238, "code"=>"asia,rare", "display_name"=>"Kroch Library Rare & Manuscripts (Non-Circulating)", "hours_page"=>"asia_rare", "rmc_aeon"=>false)
Location.create("voyager_id"=>239, "code"=>"asia,ref", "display_name"=>"Kroch Library Asia Reference (Non-Circulating)", "hours_page"=>"asia_ref", "rmc_aeon"=>false)
Location.create("voyager_id"=>240, "code"=>"asia,ranx", "display_name"=>"Kroch Library Rare & Manuscripts (Request in advance)", "hours_page"=>"asia_ranx", "rmc_aeon"=>false)
Location.create("voyager_id"=>241, "code"=>"mgmt,circ", "display_name"=>"", "hours_page"=>"mgmt_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>242, "code"=>"law,self", "display_name"=>"", "hours_page"=>"law_self", "rmc_aeon"=>false)
Location.create("voyager_id"=>243, "code"=>"lawr", "display_name"=>"Law Library (Myron Taylor Hall) Rare Books ", "hours_page"=>"lawr", "rmc_aeon"=>true)
Location.create("voyager_id"=>244, "code"=>"lawr,anx", "display_name"=>"Law Library Rare--Request in advance at Law Circulation Desk", "hours_page"=>"lawr_anx", "rmc_aeon"=>false)
Location.create("voyager_id"=>245, "code"=>"jgsm,ref2", "display_name"=>"Sage Hall Management Library Reference (Non-Circulating)", "hours_page"=>"jgsm_ref2", "rmc_aeon"=>false)
Location.create("voyager_id"=>246, "code"=>"nest,circ", "display_name"=>"", "hours_page"=>"nest_circ", "rmc_aeon"=>false)
Location.create("voyager_id"=>247, "code"=>"olin,501", "display_name"=>"Olin Library Graduate Study Room 501, Request at Circulation", "hours_page"=>"olin_501", "rmc_aeon"=>false)
Location.create("voyager_id"=>248, "code"=>"XX", "display_name"=>"", "hours_page"=>"XX", "rmc_aeon"=>false)
Location.create("voyager_id"=>249, "code"=>"WW", "display_name"=>"", "hours_page"=>"WW", "rmc_aeon"=>false)
Location.create("voyager_id"=>250, "code"=>"VV", "display_name"=>"", "hours_page"=>"VV", "rmc_aeon"=>false)
