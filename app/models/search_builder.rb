# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder


  #self.solr_search_params_logic += [:sortby_title_when_browsing, :sortby_callnum]
  self.default_processor_chain += [:sortby_title_when_browsing, :sortby_callnum]

  def sortby_title_when_browsing user_parameters
    # if no search term is submitted and user hasn't specified a sort
    # assume browsing and use the browsing sort field
    if user_parameters[:q].blank? and user_parameters[:sort].blank?
      browsing_sortby =  blacklight_config.sort_fields.values.select { |field| field.browse_default == true }.first
  #    solr_parameters[:sort] = browsing_sortby.field
    end
  end

  #sort call number searches by call number
  def sortby_callnum user_parameters
    if user_parameters[:search_field] == 'call number'
      callnum_sortby =  blacklight_config.sort_fields.values.select { |field| field.callnum_default == true }.first
      solr_parameters[:sort] = callnum_sortby.field
    end
  end




  def cjk_query_addl_params(params)
    if params && params.has_key?(:q)
      q_str = (params[:q] ? params[:q] : '')
      num_uni = num_cjk_uni(q_str)
      if num_uni > 2
        solr_params.merge!(cjk_mm_qs_params(q_str))
      end

      if num_cjk_uni(params[:q]) > 0
        cjk_query_addl_params({}, params)
      end
      
      if num_uni > 0
        case params[:search_field]
          when 'all_fields', nil
           solr_params[:q] = "{!qf=$qf pf=$pf pf3=$pf3 pf2=$pf2}#{q_str}"
          when 'title'
           solr_params[:q] = "{!qf=$title_qf pf=$title_pf pf3=$title_pf3 pf2=$title_pf2}#{q_str}"
          when 'author/creator'
           solr_params[:q] = "{!qf=$author_qf pf=$author_pf pf3=$pf3_author_pf3 pf2=$author_pf2}#{q_str}"
          when 'journal title'
           solr_params[:q] = "{!qf=$journal_qf pf=$journal_pf pf3=$journal_pf3 pf2=$journal_pf2}#{q_str}"
          when 'subject'
           solr_params[:q] = "{!qf=$subject_qf pf=$subject_pf pf3=$subject_pf3 pf2=$subject_pf2}#{q_str}"
        end
      end
    end
  end

  def cjk_mm_val
    silence_warnings { @@cjk_mm_val = '3<86%'}
  end

  def cjk_mm_qs_params(str)
 #   cjk_mm_val = []
    num_uni = num_cjk_uni(str)
    if num_uni > 2
      num_non_cjk_tokens = str.scan(/[[:alnum]]+/).size
      if num_non_cjk_tokens > 0
        lower_limit = cjk_mm_val[0].to_i
        mm = (lower_limit + num_non_cjk_tokens).to_s + cjk_mm_val[1, cjk_mm_val.size]
        {'mm' => mm, 'qs' => 0}
      else
        {'mm' => cjk_mm_val, 'qs' => 0}
      end
    else
      {}
    end
  end


  def num_cjk_uni(str)
    if str
      str.scan(/\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/).size
    else
      0
    end
  end


end
