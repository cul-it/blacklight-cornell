BEGIN { print "locations:"
        indent1 = "  " ;
        indent2 = indent1 indent1; 
AE["lawr"] =   "lawr"; 
AE["rmc"] =   "rmc"; 
AE["rmc,anx"] =   "rmc,anx"; 
AE["rmc,icer"] =   "rmc,icer"; 
AE["rmc,hsci"] =   "rmc,hsci"; 
AE["was,rare"] =   "was,rare"; 
AE["was,ranx"] =   "was,ranx"; 
AE["ech,rare"] =   "ech,rare"; 
AE["ech,ranx"] =   "ech,ranx"; 
AE["sasa,rare"] =   "sasa,rare"; 
AE["sasa,ranx"] =   "sasa,ranx"; 
AE["hote,rare"] =   "hote,rare"; 
HELP["rmc"] = "rmc";
HELP["anx"] = "annex";
HELP["afr"] = "africana";
HELP["engr"] = "engineering";
HELP["olin"] = "olin";
HELP["gnva"] = "geneva";
HELP["ilr"] = "ilr";
HELP["fine"] = "finearts";
HELP["hote"] = "hotel";
HELP["asia"] = "asia";
HELP["was"] = "asia";
HELP["ech"] = "asia";
HELP["law"] = "law";
HELP["jgsm"] = "jgsm";
HELP["mann"] = "mann";
HELP["math"] = "math";
HELP["Spacecraft Planetary Imaging Facility 317 Space Science Bldg"] = "http://spif.astro.cornell.edu/index.php?option=com_content&view=articl     e&id=9&Itemid=9";
HELP["Spacecraft Planetary Imaging Facility (Non-Circulating)"] = "http://spif.astro.cornell.edu/index.php?option=com_content&view=article&id=     9&Itemid=9";
HELP["phys"] = "http://spif.astro.cornell.edu/index.php?option=com_content&view=article&id=9&Itemid=9";
HELP["uris"] = "uris";
HELP["vet"] = "vet";
HELP["orni"] = "ornithology";
HELP["mus"] = "music";
}

{ code = $1 ; 
  code_val = $1
  name = $3
  vid = $2;
  gsub(/["]/,"",code);
  gsub(/[,]/,"_",code);
  gsub(/[ ]/,"",code);
  gsub(/[\t]/,"",code);
  gsub(/[ ]/,"",code_val);
  split(code_val,code_a,",")
  help = "help";
  if (code_a[1] == "rmc")
   help = HELP[code_a[1]];
  else if (code_a[2] ==  "anx") {
   help = HELP[code_a[2]];
  } else {
   help = HELP[code_a[1]];
  } 
  end 

 
  print indent1  code ":"
  print indent2  "code: " code_val 
  print indent2  "display_name: \"" name "\"" 
  print indent2  "voyager_id: " vid 
  if (code_val in AE) {
    print indent2  "rmc_aeon: true"
  } else {
    print  indent2  "rmc_aeon: false";
  }
  print indent2  "hours_page: " "\"" help "\"" 
}

