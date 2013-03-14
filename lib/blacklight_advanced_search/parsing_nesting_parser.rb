require 'parsing_nesting/tree'
module BlacklightAdvancedSearch::ParsingNestingParser
  
  def process_query(params,config)
    queriesTemp = []
    queries = ""
    Rails.logger.debug("parsingNesting = #{keyword_op}")
    keyword_queries.each do |field,query| 
      queriesTemp << ParsingNesting::Tree.parse(query).to_query( local_param_hash(field, config)  )            
    end
 #   queries.join( ' ' + keyword_op + ' ')
    Rails.logger.debug("fargincount = #{queriesTemp.count}")
    Rails.logger.debug("farginops = #{keyword_op}")
    for i in 0..queriesTemp.count - 2
      queries << queriesTemp[i] + ' ' + keyword_op[i] + ' '
    end
    if (queriesTemp.count - 1  > 0)
      queries << queriesTemp[queriesTemp.count - 1]
    else
      queries = "";
    end  
     
  end
  
  def local_param_hash(key, config)
    field_def = config.search_fields[key]

    (field_def[:solr_parameters] || {}).merge(field_def[:solr_local_parameters] || {})
  end
  
end
