# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController
  #include BlacklightGoogleAnalytics::ControllerExtraHead

  include Blacklight::Catalog
  include BlacklightUnapi::ControllerExtension
  include BlacklightAdvancedSearch::ParseBasicQ

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params

    config.default_solr_params = { 
      :qt => 'search',
      :rows => 20,
      :fl => '*,score'
    }

    ## list of display fields with icon
    config.display_icon = {
        'format' => 1
    }

    ## list of clickable display fields mapped to target index field
    ## target index field should be defined in add_search_field later this file
    ## target index field is searched when this link is clicked
    config.display_clickable = {
        'author_display' => 'author/creator',
        'author_addl_display' => 'author/creator',
        'subject_display' => {
            :search_field => 'subject',
            :sep => '|',
            :sep_index => ' ',
            :sep_display => ' > ',
            :hierarchical => true
        },
        'title_uniform_display' => 'title',
        'title_series_display'  => 'title',
        'continues_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'continues_in_part_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'supersedes_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'absorbed_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'absorbed_in_part_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'continued_by_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'continued_in_part_by_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'superseded_by_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'absorbed_by_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'absorbed_in_part_by_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'split_into_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'merger_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'translation_of_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'has_translation_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'other_edition_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'has_supplement_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'supplement_to_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'other_form_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        },
        'issued_with_display' => {
            :search_field => 'title',
            :sep => '|',
            :key_value => true
        }
    }

    config.display_link = {
        'url_access_display' => { :label => 'Access content' },
        'url_toc_display'    => { :label => 'Access table of contents' },
        'url_other_display'  => { :label => 'Access content' }
    }

    ## custom multi-valued fields separator
    config.multiline_display_fields = {
        'pub_info_display' => '<br/>',
        'edition_display' => '<br/>',
        'subject_display' => '<br/>',
        'notes_display' => '<br/>'
    }

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or 
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    #config.default_document_solr_params = {
    #  :qt => 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #  # :fl => '*',
    #  # :rows => 1
    #  # :q => '{!raw f=id v=$id}' 
    #}

    # solr field configuration for search results/index views
    config.index.show_link = 'title_display'
    config.index.record_display_type = 'format'

    # solr field configuration for document/show views
    config.show.html_title = 'title_display'
    config.show.heading = 'title_display'
    config.show.display_type = 'format'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar
    config.add_facet_field 'format', :label => 'Format', :limit => 3
    config.add_facet_field 'pub_date', :label => 'Publication Year', :range => {
  :num_segments => 6,
  :assumed_boundaries => [1300, Time.now.year + 2],
  :segments => true    
}, :show => true
#    config.add_facet_field 'pub_date_sort', :label => 'Publication Year', :range => {
#  :num_segments => 6,
#  :assumed_boundaries => [1300, Time.now.year + 2],
#  :segments => true    
#}, :show => true
    config.add_facet_field 'subject_topic_facet', :label => 'Topic', :limit => 5 
    config.add_facet_field 'language_facet', :label => 'Language', :limit => 5 , :show => true
    config.add_facet_field 'lc_1letter_facet', :label => 'Call Number', :limit => 3 
    config.add_facet_field 'subject_geo_facet', :label => 'Region', :limit => 5
    config.add_facet_field 'subject_era_facet', :label => 'Era', :limit => 5  
    config.add_facet_field 'location_facet', :label => 'Location', :limit => 5  


    config.add_facet_field 'hierarchy_facet', :hierarchy => true
#    config.add_facet_field 'facet', :multiple => true
#    config.add_facet_field 'first_facet,last_facet', :pivot => ['first_facet', 'last_facet']
#    config.add_facet_field 'my_query_field', :query => { 'label' => 'value:1', 'label2' => 'value:2'}
#    config.add_facet_field 'facet', :single => true
 #   config.add_facet_field 'facet', :tag => 'my_tag', :ex => 'my_tag'

   # config.default_solr_params[:'facet.field'] = config.facet_fields.keys

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
  #  config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'format'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    config.add_index_field 'title_display', :label => 'Title:' 
    config.add_index_field 'title_vern_display', :label => 'Title:' 
    config.add_index_field 'author_display', :label => 'Author:' 
    config.add_index_field 'author_vern_display', :label => 'Author:' 
    config.add_index_field 'format', :label => 'Format:' 
    config.add_index_field 'language_facet', :label => 'Language:'
    #config.add_index_field 'published_display', :label => 'Published:'
    config.add_index_field 'published_vern_display', :label => 'Published:'
    config.add_index_field 'lc_callnum_display', :label => 'Call number:'
    #config.add_index_field 'pub_date', :label => 'Publication Date:'
    config.add_index_field 'pub_info_display', :label => 'Publication:'
    config.add_index_field 'edition_display', :label => 'Edition:'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'title_display', :label => 'Title:' 
    config.add_show_field 'title_vern_display', :label => 'Title:' 
    config.add_show_field 'subtitle_display', :label => 'Subtitle:' 
    config.add_show_field 'subtitle_vern_display', :label => 'Subtitle:' 
    config.add_show_field 'title_uniform_display', :label => 'Uniform Title:'
    config.add_show_field 'title_series_display', :label => 'Series Title:'
    config.add_show_field 'continues_display', :label => 'Continues:'
    config.add_show_field 'continues_in_part_display', :label => 'Continues in Part:'
    config.add_show_field 'supersedes_display', :label => 'Supersedes:'
    config.add_show_field 'absorbed_display', :label => 'Absorbed:'
    config.add_show_field 'absorbed_in_part_display', :label => 'Absorbed in Part:'
    config.add_show_field 'continued_by_display', :label => 'Continued by:'
    config.add_show_field 'continued_in_part_by_display', :label => 'Continued in Part by:'
    config.add_show_field 'superseded_by_display', :label => 'Superseded by:'
    config.add_show_field 'absorbed_by_display', :label => 'Absorbed by:'
    config.add_show_field 'absorbed_in_part_by_display', :label => 'Absorbed in Part by:'
    config.add_show_field 'split_into_display', :label => 'Split into:'
    config.add_show_field 'merger_display', :label => 'Merger:'
    config.add_show_field 'translation_of_display', :label => 'Translation of:'
    config.add_show_field 'has_translation_display', :label => 'Has Translation:'
    config.add_show_field 'other_edition_display', :label => 'Other Edition:'
    config.add_show_field 'has_supplement_display', :label => 'Has Supplement:'
    config.add_show_field 'supplement_to_display', :label => 'Supplement to:'
    config.add_show_field 'other_form_display', :label => 'Other Form:'
    config.add_show_field 'issued_with_display', :label => 'Issued With'
    config.add_show_field 'author_display', :label => 'Author:' 
    config.add_show_field 'author_vern_display', :label => 'Author:'
    config.add_show_field 'author_addl_display', :label => 'Other Author:'
    config.add_show_field 'format', :label => 'Format:' 
    config.add_show_field 'url_fulltext_display', :label => 'URL:'
    config.add_show_field 'url_suppl_display', :label => 'More Information:'
    config.add_show_field 'language_facet', :label => 'Language:'
    #config.add_show_field 'published_display', :label => 'Published:'
    config.add_show_field 'published_vern_display', :label => 'Published:'
    config.add_show_field 'lc_callnum_display', :label => 'Call number:'
    config.add_show_field 'description_display', :label => 'Description:'
    config.add_show_field 'isbn_t', :label => 'ISBN:'
    #config.add_show_field 'pub_date', :label => 'Publication Date'
    config.add_show_field 'pub_info_display', :label => 'Publication:'
    config.add_show_field 'edition_display', :label => 'Edition:'
    config.add_show_field 'notes_display', :label => 'Notes:'
    config.add_show_field 'contents_display', :label => 'Table of Contents:'
    config.add_show_field 'partial_contents_display', :label => 'Partial Table of Contents:'
    config.add_show_field 'subject_display', :label => 'Subject: '
     config.add_show_field 'url_access_display', :label => 'Content Link:'
     config.add_show_field 'url_toc_display', :label => 'Table of Contents Link:'
     config.add_show_field 'url_other_display', :label => 'Content Link:'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 
    
    config.add_search_field 'all_fields', :label => 'All Fields'
    

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    
    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params. 
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = { 
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end

    # config.add_search_field('title abbreviation', :qt => 'standard') do |field|  
    #   # solr_parameters hash are sent to Solr as ordinary url query params.   
    #   field.solr_parameters = {  
    #     :'spellcheck.dictionary' => 'title_ngram'  
    #   }  
  
    #   # :solr_local_parameters will be sent using Solr LocalParams  
    #   # syntax, as eg {! qf=$title_qf }. This is neccesary to use  
    #   # Solr parameter de-referencing like $title_qf.  
    #   # See: http://wiki.apache.org/solr/LocalParams  
    #   field.cornell_solr_parameters = {  
    #     :query_field => 'title_ngram'  
    #   }  
    # end
    
    #config.add_search_field(
    #    :value => 'author/creator',
    #    :key => 'author',
    #    :solr_parameters => { :'spellcheck.dictionary' => 'author' },
    #    :solr_local_parameters => { 
    #      :qf => '$author_qf',
    #      :pf => '$author_pf'
    #    }
    #)
    config.add_search_field('author/creator') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = { 
        :qf => '$author_qf',
        :pf => '$author_pf'
      }
    end
    config.add_search_field('call number') do |field|
#      field.solr_parameters = { :'spellcheck.dictionary' => 'callnumber' }
      field.solr_local_parameters = { 
        :qf => '$lc_callnum_qf',
        :pf => '$lc_callnum_pf'
      }
    end
    config.add_search_field('publisher') do |field|
#      field.solr_parameters = { :'spellcheck.dictionary' => 'callnumber' }
      field.solr_local_parameters = { 
        :qf => '$publisher_qf',
        :pf => '$publisher_pf'
      }
    end
    
    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as 
    # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = { 
        :qf => '$subject_qf',
        :pf => '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
    config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year descending'
    config.add_sort_field 'pub_date_sort asc, title_sort asc', :label => 'year ascending'
    config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author A-Z'
    config.add_sort_field 'author_sort desc, title_sort asc', :label => 'author Z-A'
    config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title A-Z'
    config.add_sort_field 'title_sort desc, pub_date_sort desc', :label => 'title Z-A'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end



end 
