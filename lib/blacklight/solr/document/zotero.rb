# This module registers the ZOTERO RDF export format with the system so that
# we can offer export the option of direct export to  Zotero.
module Blacklight::Solr::Document::Zotero

  def self.extended(document)
    # Register our exportable formats
    Blacklight::Solr::Document::Zotero.register_export_formats( document )
  end

  def self.register_export_formats(document)
    document.will_export_as(:rdf_zotero, "application/xml")
  end

  def export_as_rdf_zotero
   generate_rdf_zotero  
  end


  def generate_rdf_zotero
    about = "http://newcatalog.library.cornell.edu/catalog/#{id}"
    title = "#{clean_end_punctuation(setup_title_info(to_marc))}"
    fmt = self['format'].first
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} #{fmt.inspect}"
    ty = "book"
    if (FACET_TO_ZOTERO_TYPE.keys.include?(fmt))
      ty =  "#{FACET_TO_ZOTERO_TYPE[fmt]}"
    end
    tag = case ty 
       when 'videoRecording' 
        "Recording" 
       when  'audioRecording'
        "Recording" 
       when  'map'
        "Image" 
      else
        "Book"
      end
    builder = Builder::XmlMarkup.new(:indent => 2,:margin => 4)
    builder.tag!("rdf:RDF",
    'xmlns:rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    'xmlns:z'   => "http://www.zotero.org/namespaces/export#",
    'xmlns:dc'  => "http://purl.org/dc/elements/1.1/",
    'xmlns:vcard' => "http://nwalsh.com/rdf/vCard#",
    'xmlns:foaf'=> "http://xmlns.com/foaf/0.1/",
    'xmlns:bib' => "http://purl.org/net/biblio#",
    'xmlns:prism' => "http://prismstandard.org/namespaces/1.2/basic/",
    'xmlns:dcterms' =>"http://purl.org/dc/terms/") do
      builder.bib(tag.to_sym) do 
        builder.z(:itemType,"#{ty}")
        builder.dc(:title, title.strip)
        generate_rdf_authors(builder,ty)
        generate_rdf_publisher(builder)
        generate_rdf_pubdate(builder)
        generate_rdf_edition(builder)
        generate_rdf_language(builder)
        generate_rdf_kw(builder)
        generate_rdf_abstract(builder)
        generate_rdf_url(builder)
        generate_rdf_isbn(builder)
        generate_rdf_doi(builder)
        generate_rdf_holdings(builder)
        generate_rdf_medium(builder,ty)
        generate_rdf_catlink(builder,ty)
        generate_rdf_specific(builder,ty)
      end
    end
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} #{builder.target!.inspect}"
    builder.target! 
  end

 #   <dc:identifier>
 #       <dcterms:URI>
 #           <rdf:value>http://portal.acm.org/citation.cfm?id=1183550.1183564</rdf:value>
 #       </dcterms:URI>
 #   </dc:identifier>
  def generate_rdf_url(b)
    if !self['url_access_display'].blank?
      ul = self['url_access_display'].first.split('|').first
       ul.sub!('http://proxy.library.cornell.edu/login?url=','')
       ul.sub!('http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=','')
    end
    b.dc(:identifier) { b.dcterms(:URI) { b.rdf(:value,ul)}}  unless ul.blank? 
  end   
    #<dcterms:abstract>Backup of websites is often not considered until </dcterms:abstract>
    
  def generate_rdf_abstract(b)
    k = setup_abst_info(to_marc)
    b.dcterms(:abstract,k.join(' ')) unless k.blank?
  end
#        <dc:coverage>http://newcatalog.library.cornell.edu/catalog/1001</dc:coverage>
#holdings_record_display"=>
#    ["{\"id\":\"17239\",\"modified_date\":\"20150710111357\",\"copy_number\":null,\"callnos\":[\"QE285 .A19 no.2\"],\"notes\":[],\"holdings_desc\":[\"text\"],\"recent_holdings_desc\":[],\"supplemental_holdings_desc\":[],\"index_holdings_desc\":[],\"locations\":[{\"code\":\"engr,anx\",\"number\":21,\"name\":\"Library Annex\",\"library\":\"Library Annex\"}]}",
#     "{\"id\":\"17240\",\"modified_date\":null,\"copy_number\":null,\"callnos\":[\"G6041s.C5 100 S3 Sheet 11\"],\"notes\":[],\"holdings_desc\":[\"map\"],\"recent_holdings_desc\":[],\"supplemental_holdings_desc\":[],\"index_holdings_desc\":[],\"locations\":[{\"code\":\"maps\",\"number\":80,\"name\":\"Olin Library Maps (Non-Circulating)\",\"library\":\"Olin Library\"}]}"],
#      <dc:subject>
#          <dcterms:LCC><rdf:value>BF23.11.19</rdf:value></dcterms:LCC>
#       </dc:subject>`

  def generate_rdf_medium(b,ty)
      if ty == 'audioRecording'
        medium = setup_medium(to_marc,'song')
        b.tag!("z:medium",medium)  unless medium.blank?
      end
      if ty == 'videoRecording'
        medium = setup_medium(to_marc,'song')
        b.tag!("z:medium",medium)  unless medium.blank?
      end
  end

  def generate_rdf_holdings(b)
    where = setup_holdings_info(b) 
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} #{where.inspect}"
    #b.dc(:coverage,where.join("\n")) unless where.blank? or where.join("").blank?
    b.dc(:subject) { b.dcterms(:LCC) { b.rdf(:value,where.join("//")) }}  unless where.blank? or where.join("").blank?
  end


    #<dc:identifier>ISBN 978-1-57027-139-7</dc:identifier>
  def generate_rdf_isbn(b)
    isbns = setup_isbn_info(to_marc)
    isbns.each do |k|
      b.dc(:identifier,"ISBN #{k}") unless k.blank? 
    end
  end
    #<dc:identifier>DOI 10.1371/journal.pone.0118512</dc:identifier>
  def generate_rdf_doi(b)
    doi = setup_doi(to_marc)
    b.dc(:description,"DOI #{doi}") unless doi.blank? 
    b.dc(:description,"just some random text") unless doi.blank? 
  end

    # edition
    # <prism:edition>3rd. ed</prism:edition>
  def generate_rdf_edition(b)
    et =  setup_edition(to_marc)
    b.prism(:edition,et) unless et.blank?
  end
    #<dc:subject>
    #  <z:AutomaticTag><rdf:value>Social aspects</rdf:value></z:AutomaticTag>
    #</dc:subject>
  def generate_rdf_kw(b)
    kw =   setup_kw_info(to_marc)
    kw.each do |k|
      b.dc(:subject,k) unless k.empty? 
    end
  end

  def generate_rdf_publisher(b)
    # publisher
    pub_data = setup_pub_info(to_marc) # This function combines publisher and place
    place = ''
    pname = ''
    if !pub_data.nil?
      place, publisher = pub_data.split(':')
      pname = "#{publisher.strip!}" unless publisher.nil?
      # publication place
    end
    b.dc(:publisher) {
      b.foaf(:Organization) {
        b.vcard(:adr) {
          b.vcard(:Address) {
            b.vcard(:locality, place ) unless place.blank?
          }
        }
        b.foaf(:name, pname ) unless pname.blank?
      }
    }
  end

  def generate_rdf_language(b)
    # language
    if !self["language_facet"].blank?
      self["language_facet"].map{|la|  b.z(:language,la)
      }
    end
  end

  def generate_rdf_pubdate(b)
    # publication year
    yr  = "#{setup_pub_date(to_marc)}"
    b.dc(:date,yr) unless yr.empty? 
  end

  def generate_rdf_person(b,p)
    surname = p
    surname, givenname = p.split(',') unless !p.include?(",")
    b.foaf(:Person) do 
      sn = surname.index('(').nil? ? surname : surname[0,surname.index('(')].rstrip
      b.foaf(:surname,sn.strip) unless sn.blank?
      b.foaf(:givenname,givenname.strip) unless givenname.blank?
    end
   end

  def generate_rdf_authors(bld,ty)
    # Handle authors
    authors = get_all_authors(to_marc)
    relators =  get_contrib_roles(to_marc)
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} relators #{relators.inspect}"
    primary_authors = authors[:primary_authors]
    if primary_authors.blank? and !authors[:primary_corporate_authors].blank?
      primary_authors = authors[:primary_corporate_authors]
    end
    Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} prmry authors=#{primary_authors.inspect}"
    secondary_authors = authors[:secondary_authors]
    meeting_authors = authors[:meeting_authors]
    secondary_authors.delete_if { | a | relators.has_key?(a) and !relators[a].blank? }
    primary_authors.delete_if { | a | relators.has_key?(a) and !relators[a].blank? }
    editors = authors[:editors]
    if editors.empty?
      editors = relators.select {|k,v| v.include?("edt") }.keys
      Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} looking for editors #{relators.inspect}"
      Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} editors #{editors.inspect}"
    end
    pa = primary_authors.blank? ? secondary_authors : primary_authors
    #pa = primary_authors + secondary_authors
    author_text = ''
    editor_text = ''
    auty =  case ty 
              when 'videoRecording'  
                'contributors' 
              when 'audioRecording'  
                primary_authors.blank? ? 'contributors' : 'performers'
              when 'map'  
                primary_authors.blank? ? 'contributors' : 'cartographers'
              else
                'authors'
             end 
    if !pa.blank?
      ns = ['contributors','authors','editors'].include?(auty)  ? 'bib' : 'z'
      bld.tag!("#{ns}:#{auty}") { 
        bld.rdf(:Seq) {
            pa.map { |a|     bld.rdf(:li) { generate_rdf_person(bld,a) } }
        }
      }
    end 
    edty = ty == 'videoRecording' ? 'contributors' : 'editors'
    if !editors.blank?
      bld.bib(edty.to_sym ) {
        bld.rdf(:Seq) {
            editors.map { |a|     bld.rdf(:li) { generate_rdf_person(bld,a) } }
        }
      }
    end 
    if pa.blank? && editors.blank? && !relators.blank?
      Rails.logger.debug "********es287_dev #{__FILE__} #{__LINE__} #{__method__} meeting authors #{meeting_authors.inspect}"
      relators.each { |n,r| 
        rel = relator_to_zotero(r[0]) 
        ns = ['contributors','authors','editors'].include?(rel)  ? 'bib' : 'z'
        bld.tag!("#{ns}:#{rel}") { bld.rdf(:Seq) { bld.rdf(:li) { generate_rdf_person(bld,n) } } }
        #if ['contributors','authors','editors'].include?(rel) 
        #  bld.bib(rel.to_sym) { bld.rdf(:Seq) { bld.rdf(:li) { generate_rdf_person(bld,n) } } }
        #else
        #  bld.z(rel.to_sym) { bld.rdf(:Seq) { bld.rdf(:li) { generate_rdf_person(bld,n) } } }
        #end
      }
    end
  end

  # if e-resource  
  #  put catalog link in coverage 
  # else 
  #  put in url field. 
  def generate_rdf_catlink(b,ty)
    ul =  "http://newcatalog.library.cornell.edu/catalog/#{id}" 
    # if no elect access data, 'description' field.
    b.dc(:description,ul)
    #if self['url_access_display'].blank?
      #b.dc(:identifier) { b.dcterms(:URI) { b.rdf(:value,ul)}}
      #else 
      #b.dc(:coverage,ul)
    #eend
  end 
  # add info specific to an item type.
  def generate_rdf_specific(b,ty)
    case ty
      when 'thesis'
        b.z(:type) {"Ph.D. dissertation"}  
      else
    end
  end 

  def relator_to_zotero(rel)
    if RELATOR_CODES_ZRDF.has_key?(rel) 
      RELATOR_CODES_ZRDF[rel] 
    else  
      "contributors"
    end 
  end
  
    
FACET_TO_ZOTERO_TYPE =  { "ABST"=>"ABST", "ADVS"=>"ADVS", "AGGR"=>"AGGR",
  "ANCIENT"=>"ANCIENT", "ART"=>"ART", "BILL"=>"BILL", "BLOG"=>"BLOG",
  "Book"=>"book", "CASE"=>"CASE", "CHAP"=>"CHAP", "CHART"=>"CHART",
  "CLSWK"=>"CLSWK", "COMP"=>"COMP", "CONF"=>"CONF", "CPAPER"=>"CPAPER",
  "CTLG"=>"CTLG", "DATA"=>"DATA", "Database"=>"DBASE", "DICT"=>"DICT",
  "EBOOK"=>"EBOOK", "ECHAP"=>"ECHAP", "EDBOOK"=>"EDBOOK", "EJOUR"=>"EJOUR",
  "ELEC"=>"ELEC", "ENCYC"=>"ENCYC", "EQUA"=>"EQUA", "FIGURE"=>"FIGURE",
  "GEN"=>"GEN", "GOVDOC"=>"GOVDOC", "GRANT"=>"GRANT", "HEAR"=>"HEAR",
  "ICOMM"=>"ICOMM", "INPR"=>"INPR", "JFULL"=>"JFULL", "JOUR"=>"JOUR",
  "LEGAL"=>"LEGAL", "Manuscript/Archive"=>"manuscript", "Map or Globe"=>"map", "MGZN"=>"MGZN",
  "MPCT"=>"MPCT", "MULTI"=>"MULTI", "Musical Score"=>"MUSIC", "NEWS"=>"NEWS",
  "PAMP"=>"PAMP", "PAT"=>"PAT", "PCOMM"=>"PCOMM", "RPRT"=>"RPRT",
  "SER"=>"SER", "SLIDE"=>"SLIDE", "Non-musical Recording"=>"audioRecording", "Musical Recording"=>"audioRecording",
  "STAND"=>"STAND",
  "STAT"=>"STAT", "Thesis"=>"thesis", "UNPB"=>"UNPB", "Video"=>"videoRecording"
  }

RELATOR_CODES_ZRDF = {
 "abr" => "contributors",
 "act" => "contributors",
 "adp" => "contributors",
 "rcp" => "contributors",
 "anl" => "contributors",
 "anm" => "contributors",
 "ann" => "contributors",
 "apl" => "contributors",
 "ape" => "contributors",
 "app" => "contributors",
 "arc" => "contributors",
 "arr" => "contributors",
 "acp" => "contributors",
 "adi" => "contributors",
 "art" => "contributors",
 "ard" => "contributors",
 "asg" => "contributors",
 "asn" => "contributors",
 "att" => "contributors",
 "auc" => "contributors",
 "aut" => "authors",
 "aqt" => "contributors",
 "aft" => "contributors",
 "aud" => "contributors",
 "aui" => "contributors",
 "ato" => "contributors",
 "ant" => "contributors",
 "bnd" => "contributors",
 "bdd" => "contributors",
 "blw" => "contributors",
 "bkd" => "contributors",
 "bkp" => "contributors",
 "bjd" => "contributors",
 "bpd" => "contributors",
 "bsl" => "contributors",
 "brl" => "contributors",
 "brd" => "contributors",
 "cll" => "contributors",
 "ctg" => "cartographers",
 "cas" => "contributors",
 "cns" => "contributors",
 "chr" => "contributors",
 "cng" => "contributors",
 "cli" => "contributors",
 "cor" => "contributors",
 "col" => "contributors",
 "clt" => "contributors",
 "clr" => "contributors",
 "cmm" => "contributors",
 "cwt" => "contributors",
 "com" => "contributors",
 "cpl" => "contributors",
 "cpt" => "contributors",
 "cpe" => "contributors",
 "cmp" => "composers",
 "cmt" => "contributors",
 "ccp" => "contributors",
 "cnd" => "contributors",
 "con" => "contributors",
 "csl" => "contributors",
 "csp" => "contributors",
 "cos" => "contributors",
 "cot" => "contributors",
 "coe" => "contributors",
 "cts" => "contributors",
 "ctt" => "contributors",
 "cte" => "contributors",
 "ctr" => "contributors",
 "ctb" => "contributors",
 "cpc" => "contributors",
 "cph" => "contributors",
 "crr" => "contributors",
 "crp" => "contributors",
 "cst" => "contributors",
 "cou" => "contributors",
 "crt" => "contributors",
 "cov" => "contributors",
 "cre" => "authors",
 "cur" => "contributors",
 "dnc" => "contributors",
 "dtc" => "contributors",
 "dtm" => "contributors",
 "dte" => "contributors",
 "dto" => "contributors",
 "dfd" => "contributors",
 "dft" => "contributors",
 "dfe" => "contributors",
 "dgg" => "contributors",
 "dgs" => "contributors",
 "dln" => "contributors",
 "dpc" => "contributors",
 "dpt" => "contributors",
 "dsr" => "contributors",
 "drt" => "contributors",
 "dis" => "contributors",
 "dbp" => "contributors",
 "dst" => "contributors",
 "dnr" => "contributors",
 "drm" => "contributors",
 "dub" => "contributors",
 "edt" => "editors",
 "edc" => "editors",
 "edm" => "editors",
 "elg" => "contributors",
 "elt" => "contributors",
 "enj" => "contributors",
 "eng" => "contributors",
 "egr" => "contributors",
 "etr" => "contributors",
 "evp" => "contributors",
 "exp" => "contributors",
 "fac" => "contributors",
 "fld" => "contributors",
 "fmd" => "directors",
 "fds" => "contributors",
 "flm" => "contributors",
 "fmp" => "producers",
 "fmk" => "contributors",
 "fpy" => "contributors",
 "frg" => "contributors",
 "fmo" => "contributors",
 "fnd" => "contributors",
 "gis" => "contributors",
 "hnr" => "contributors",
 "hst" => "contributors",
 "his" => "contributors",
 "ilu" => "contributors",
 "ill" => "contributors",
 "ins" => "contributors",
 "itr" => "contributors",
 "ive" => "contributors",
 "ivr" => "contributors",
 "inv" => "contributors",
 "isb" => "contributors",
 "jud" => "contributors",
 "jug" => "contributors",
 "lbr" => "contributors",
 "ldr" => "contributors",
 "lsa" => "contributors",
 "led" => "contributors",
 "len" => "contributors",
 "lil" => "contributors",
 "lit" => "contributors",
 "lie" => "contributors",
 "lel" => "contributors",
 "let" => "contributors",
 "lee" => "contributors",
 "lbt" => "contributors",
 "lse" => "contributors",
 "lso" => "contributors",
 "lgd" => "contributors",
 "ltg" => "contributors",
 "lyr" => "wordsBys",
 "mfp" => "contributors",
 "mfr" => "contributors",
 "mrb" => "contributors",
 "mrk" => "contributors",
 "med" => "contributors",
 "mdc" => "contributors",
 "mte" => "contributors",
 "mtk" => "contributors",
 "mod" => "contributors",
 "mon" => "contributors",
 "mcp" => "contributors",
 "msd" => "contributors",
 "mus" => "contributors",
 "nrt" => "contributors",
 "osp" => "contributors",
 "opn" => "contributors",
 "orm" => "contributors",
 "org" => "contributors",
 "oth" => "contributors",
 "own" => "contributors",
 "pan" => "contributors",
 "ppm" => "contributors",
 "pta" => "contributors",
 "pth" => "contributors",
 "pat" => "contributors",
 "prf" => "performers",
 "pma" => "contributors",
 "pht" => "contributors",
 "ptf" => "contributors",
 "ptt" => "contributors",
 "pte" => "contributors",
 "plt" => "contributors",
 "pra" => "contributors",
 "pre" => "contributors",
 "prt" => "contributors",
 "pop" => "contributors",
 "prm" => "contributors",
 "prc" => "contributors",
 "pro" => "contributors",
 "prn" => "contributors",
 "prs" => "contributors",
 "pmn" => "contributors",
 "prd" => "contributors",
 "prp" => "contributors",
 "prg" => "contributors",
 "pdr" => "contributors",
 "pfr" => "contributors",
 "prv" => "contributors",
 "pup" => "contributors",
 "pbl" => "contributors",
 "pbd" => "contributors",
 "ppt" => "contributors",
 "rdd" => "contributors",
 "rpc" => "contributors",
 "rce" => "contributors",
 "rcd" => "contributors",
 "red" => "contributors",
 "ren" => "contributors",
 "rpt" => "contributors",
 "rps" => "contributors",
 "rth" => "contributors",
 "rtm" => "contributors",
 "res" => "contributors",
 "rsp" => "contributors",
 "rst" => "contributors",
 "rse" => "contributors",
 "rpy" => "contributors",
 "rsg" => "contributors",
 "rsr" => "contributors",
 "rev" => "contributors",
 "rbr" => "contributors",
 "sce" => "contributors",
 "sad" => "contributors",
 "aus" => "contributors",
 "scr" => "contributors",
 "scl" => "contributors",
 "spy" => "contributors",
 "sec" => "contributors",
 "sll" => "contributors",
 "std" => "contributors",
 "stg" => "contributors",
 "sgn" => "contributors",
 "sng" => "contributors",
 "sds" => "contributors",
 "spk" => "contributors",
 "spn" => "contributors",
 "sgd" => "contributors",
 "stm" => "contributors",
 "stn" => "contributors",
 "str" => "contributors",
 "stl" => "contributors",
 "sht" => "contributors",
 "srv" => "contributors",
 "tch" => "contributors",
 "tcd" => "contributors",
 "tld" => "contributors",
 "tlp" => "contributors",
 "ths" => "contributors",
 "trc" => "contributors",
 "trl" => "translators",
 "tyd" => "contributors",
 "tyg" => "contributors",
 "uvp" => "contributors",
 "vdg" => "contributors",
 "vac" => "contributors",
 "wit" => "contributors",
 "wde" => "contributors",
 "wdc" => "contributors",
 "wam" => "contributors",
 "wac" => "contributors",
 "wal" => "contributors",
 "wat" => "contributors",
 "win" => "contributors",
 "wpr" => "contributors",
 "wst" => "contributors" 
}
end
#<rdf:RDF
# xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
# xmlns:z="http://www.zotero.org/namespaces/export#"
# xmlns:dc="http://purl.org/dc/elements/1.1/"
# xmlns:vcard="http://nwalsh.com/rdf/vCard#"
# xmlns:foaf="http://xmlns.com/foaf/0.1/"
# xmlns:bib="http://purl.org/net/biblio#"
# xmlns:dcterms="http://purl.org/dc/terms/">
#    <bib:Book rdf:about="urn:isbn:978-1-57027-139-7">
#        <z:itemType>book</z:itemType>
#        <dc:publisher>
#            <foaf:Organization>
#                <vcard:adr>
#                    <vcard:Address>
#                       <vcard:locality>Brooklyn  NY  USA</vcard:locality>
#                    </vcard:Address>
#                </vcard:adr>
#                <foaf:name>Autonomedia</foaf:name>
#            </foaf:Organization>
#        </dc:publisher>
#        <bib:authors>
#            <rdf:Seq>
#                <rdf:li>
#                    <foaf:Person>
#                        <foaf:surname>Fuller</foaf:surname>
#                        <foaf:givenname>Matthew</foaf:givenname>
#                    </foaf:Person>
#                </rdf:li>
#            </rdf:Seq>
#        </bib:authors>
#        <dcterms:isReferencedBy rdf:resource="#item_4342"/>
#        <dc:subject>http;//newcatalog.library.cornell.edu/behind_the_blip</dc:subject>
#        <dc:identifier>ISBN 978-1-57027-139-7</dc:identifier>
#        <dc:date>2003</dc:date>
#        <dc:subject>
#           <dcterms:LCC><rdf:value>BF23.11.19</rdf:value></dcterms:LCC>
#        </dc:subject>
#        <dc:coverage>http://newcatalog.library.cornell.edu/catalog/1001</dc:coverage>
#        <dc:description>this is extra.</dc:description>
#        <z:libraryCatalog>http://newcatalog.library.cornell.edu</z:libraryCatalog>
#        <dc:title>Behind the blip : essays on the culture of software</dc:title>
#        <z:shortTitle>Behind the blip</z:shortTitle>
#        <z:archive>http://newcatalog.library.cornell.edu/catalog/unapi?id=1001</z:archive>
#        <dcterms:abstract>Backup of websites is often not considered until </dcterms:abstract>
#    </bib:Book>
#    <bib:Memo rdf:about="#item_4342">
#        <rdf:value>&lt;p&gt;to borrow.&lt;/p&gt;</rdf:value>
#        <dc:subject>to_borrow</dc:subject>
#    </bib:Memo>
#a</rdf:RDF>
