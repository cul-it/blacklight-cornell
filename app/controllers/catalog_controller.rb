# -*- encoding : utf-8 -*-
class CatalogController < ApplicationController
  include Blacklight::Marc::Catalog
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog
  include BlacklightUnapi::ControllerExtension
#  include BlacklightCornellAdvancedSearch::ParseBasicQ

  # Ensure that the configuration file is present
  begin
    SEARCH_API_CONFIG = YAML.load_file("#{::Rails.root}/config/search_apis.yml")
  rescue Errno::ENOENT
    puts <<-eos

    ******************************************************************************
    Your search_apis.yml config file is missing.
    See config/search_apis.yml.example
    ******************************************************************************

    eos
  end

  # Tweak search param logic for default sort when browsing
  # Follow documentation in project wiki
  # https://github.com/projectblacklight/blacklight/wiki/Extending-or-Modifying-Blacklight-Search-Behavior
  self.solr_search_params_logic << :sortby_title_when_browsing

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params

    config.default_solr_params = {
      :qt => 'search',
      :rows => 20,
# DISCOVERYACCESS-1472      :fl => '*,score',
# Look into removing :fl entirely during off sprint
#      :fl => 'id title_display fulltitle_display fulltitle_vern_display title_uniform_display subtitle_display author_display language_display pub_date_display format url_access_display item_record_display holdings_record_display score',
      :defType => 'edismax',
      :"f.lc_callnum_facet.facet.limit" => "-1"
    }

    ## list of display fields with icon
    config.display_icon = {
        'format' => 1
    }

    ## list of clickable display fields mapped to target index field
    ## target index field should be defined in add_search_field later this file
    ## target index field is searched when this link is clicked
    config.display_clickable = {
        'author_cts' => {
            :search_field => 'author/creator',
            :sep => '|',
            :sep_display => ' / ',
            :pair_list => true
        },
        'author_addl_cts' => {
            :search_field => 'author/creator',
            :sep => '|',
            :sep_display => ' / ',
            :pair_list => true
        },
        'title_series_cts' => {
          :search_field => 'title',
          :sep => '|',
          :key_value => true
        },
        'subject_cts' => {
            :search_field => 'subject',
            :sep => '|',
            :sep_index => ' ',
            :sep_display => ' > ',
            :hierarchical => true
        },
        'title_uniform_display' => {
            :search_field => 'title',
            :related_search_field => 'author/creator',
            :sep => '|',
            :key_value => true
        },
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
        },
        'included_work_display' => {
            :search_field => 'title',
            :related_search_field => 'author/creator',
            :sep => '|',
            :key_value => true
        },
        'related_work_display' => {
            :search_field => 'title',
            :related_search_field => 'author/creator',
            :sep => '|',
            :key_value => true
        }
    }

    config.display_link = {
        'url_access_display' => { :label => 'Access content' },
        'url_other_display'  => { :label => 'Other online content' },
        'url_bookplate_display'  => { :label => 'Bookplate' },
        'url_findingaid_display'  => { :label => 'Finding Aid' }

    }

    ## custom multi-valued fields separator
    config.multiline_display_fields = {
        'pub_info_display' => '<br/>',
        'edition_display' => '<br/>',
        'subject_display' => '<br/>',
        'notes' => '<br/>'
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
    config.index.title_field = 'title_display', 'subtitle_display', 'fulltitle_vern_display' #display as 'fulltitle_vern / title : subtitle'
    config.index.display_type_field = 'format'

    # solr field configuration for document/show views
    config.show.title_field = 'title_display'
    config.show.display_type_field = 'format'

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
    config.add_facet_field 'online', :label => 'Access', :limit => 2, :collapse => false
    config.add_facet_field 'format', :label => 'Format', :limit => 10, :collapse => false
    config.add_facet_field 'author_facet', :label => 'Author, etc.', :limit => 5
    config.add_facet_field 'pub_date_facet', :label => 'Publication Year', :range => {
      :num_segments => 6,
      :assumed_boundaries => [1300, Time.now.year + 1],
      :segments => true,
      :include_in_advanced_search => false
    }, :show => true, :include_in_advanced_search => false

    config.add_facet_field 'language_facet', :label => 'Language', :limit => 5 , :show => true
    config.add_facet_field 'fast_topic_facet', :label => 'Subject', :limit => 5
    config.add_facet_field 'fast_geo_facet', :label => 'Subject: Region', :limit => 5
    config.add_facet_field 'fast_era_facet', :label => 'Subject: Era', :limit => 5
    config.add_facet_field 'fast_genre_facet', :label => 'Genre', :limit => 5
    config.add_facet_field 'subject_content_facet', :label => 'Fiction/Non-Fiction', :limit => 5
    config.add_facet_field 'lc_alpha_facet', :label => 'Call Number', :limit => 5, :show => false
    config.add_facet_field 'location_facet', :label => 'Library Location', :limit => 5
    config.add_facet_field 'hierarchy_facet', :hierarchy => true
    config.add_facet_field 'authortitle_facet', :show => false, :label => "Author-Title"
     config.add_facet_field 'lc_callnum_facet',
                           label: 'Call Number',
                           partial: 'blacklight/hierarchy/facet_hierarchy',
                           sort: 'index'
    config.facet_display = {
      :hierarchy => {
        'lc_callnum' => [['facet'], ':']
      }
  }

    config.add_facet_field 'collection', :show => false





    # config.add_facet_field 'facet', :multiple => true
    # config.add_facet_field 'first_facet,last_facet', :pivot => ['first_facet', 'last_facet']
    # config.add_facet_field 'my_query_field', :query => { 'label' => 'value:1', 'label2' => 'value:2'}
    # config.add_facet_field 'facet', :single => true
    # config.add_facet_field 'facet', :tag => 'my_tag', :ex => 'my_tag'

    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    config.add_facet_fields_to_solr_request!


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    # config.default_solr_params[:'facet.field'] = config.facet_fields.keys

    #use this instead if you don't want to query facets marked :show=>false
    # config.default_solr_params[:'format'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    # PLEASE NOTE: The index_field config is not used in our app, instead
    #   we are specifying desired fields directly in the search results view:
    #   See _index_default.html.erb
    config.add_index_field 'title_display', :label => 'Title'
    config.add_index_field 'title_vern_display', :label => 'Title'
    config.add_index_field 'author_display', :label => 'Author'
    config.add_index_field 'author_vern_display', :label => 'Author'
    config.add_index_field 'format', :label => 'Format', :helper_method => :render_format_value
    config.add_index_field 'language_display', :label => 'Language'
    #config.add_index_field 'published_display', :label => 'Published:'
    #config.add_index_field 'published_vern_display', :label => 'Published'
    config.add_index_field 'lc_callnum_display', :label => 'Call number'
    config.add_index_field 'pub_date', :label => 'Publication date'
    config.add_index_field 'pub_info_display', :label => 'Publication'
    config.add_index_field 'edition_display', :label => 'Edition'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # These 3 title related fields called directly in _show_metadata partial
    # -- title_display
    # -- subtitle_display
    # -- title_responsibility_display
    config.add_show_field 'title_uniform_display', :label => 'Uniform title'
    config.add_show_field 'author_cts', :label => 'Author, etc.'
    config.add_show_field 'format', :label => 'Format'
    config.add_show_field 'language_display', :label => 'Language'
    config.add_show_field 'edition_display', :label => 'Edition'
    config.add_show_field 'pub_info_display', :label => 'Published'
    config.add_show_field 'pub_prod_display', :label => 'Produced'
    config.add_show_field 'pub_dist_display', :label => 'Distributed'
    config.add_show_field 'pub_manu_display', :label => 'Manufactured'
    config.add_show_field 'pub_copy_display', :label => 'Copyright date'
    config.add_show_field 'publisher_number_display', :label => 'Publisher number'
    config.add_show_field 'other_identifier_display', :label => 'Other identifier'
    config.add_show_field 'cite_as_display', :label => 'Cite as'
    config.add_show_field 'historical_note_display', :label => 'Biographical/ Historical note'
    config.add_show_field 'finding_aids_display', :label => 'Finding aid'
    config.add_show_field 'subject_cts', :label => 'Subject'
    config.add_show_field 'summary_display', :label => 'Summary'
    config.add_show_field 'description_display', :label => 'Description'
    #config.add_show_field 'isbn_t', :label => 'ISBN'
    config.add_show_field 'issn_display', :label => 'ISSN'
    config.add_show_field 'isbn_display', :label => 'ISBN'
    config.add_show_field 'frequency_display', :label => 'Frequency'
    config.add_show_field 'author_addl_cts', :label => 'Other contributor'
    config.add_show_field 'contents_display', :label => 'Table of contents'
    config.add_show_field 'partial_contents_display', :label => 'Partial table of contents'
    config.add_show_field 'title_other_display', :label => 'Other title'
    config.add_show_field 'included_work_display', :label => 'Included work'
    config.add_show_field 'related_work_display', :label => 'Related Work'
    config.add_show_field 'title_series_cts', :label => 'Series'
    config.add_show_field 'continues_display', :label => 'Continues'
    config.add_show_field 'continues_in_part_display', :label => 'Continues in part'
    config.add_show_field 'supersedes_display', :label => 'Supersedes'
    config.add_show_field 'absorbed_display', :label => 'Absorbed'
    config.add_show_field 'absorbed_in_part_display', :label => 'Absorbed in part'
    config.add_show_field 'continued_by_display', :label => 'Continued by'
    config.add_show_field 'continued_in_part_by_display', :label => 'Continued in part by'
    config.add_show_field 'superseded_by_display', :label => 'Superseded by'
    config.add_show_field 'absorbed_by_display', :label => 'Absorbed by'
    config.add_show_field 'absorbed_in_part_by_display', :label => 'Absorbed in part by'
    config.add_show_field 'split_into_display', :label => 'Split into'
    config.add_show_field 'merger_display', :label => 'Merger'
    config.add_show_field 'translation_of_display', :label => 'Translation of'
    config.add_show_field 'has_translation_display', :label => 'Has translation'
    config.add_show_field 'other_edition_display', :label => 'Other edition'
    config.add_show_field 'indexed_selectively_by_display', :label => 'Indexed Selectively By'
    config.add_show_field 'indexed_by_display', :label => 'Indexed By'
    config.add_show_field 'references_display', :label => 'References'
    config.add_show_field 'indexed_in_its_entirety_by_display', :label => 'Indexed in its Entity By'
    config.add_show_field 'in_display', :label => 'In'
    config.add_show_field 'map_format_display', :label => 'Map Format'
    config.add_show_field 'has_supplement_display', :label => 'Has supplement'
    config.add_show_field 'supplement_to_display', :label => 'Supplement to'
    config.add_show_field 'other_form_display', :label => 'Other form'
    config.add_show_field 'issued_with_display', :label => 'Issued with'
    config.add_show_field 'notes', :label => 'Notes'
    config.add_show_field 'donor_display', :label => 'Donor'
    config.add_show_field 'url_bookplate_display', :label => 'Bookplate'
    config.add_show_field 'url_other_display', :label => 'Other online content'

    # config.add_show_field 'restrictions_display', :label => 'Restrictions' #called directly in _show_metadata partial

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

    config.add_search_field 'all_fields', :label => 'All Fields', :include_in_advanced_search => true

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
    config.add_search_field('journal title') do |field|
      field.solr_parameters = { :'format' => "Journal" }
      field.solr_local_parameters = {
        :qf => '$title_qf',
        :pf => '$title_pf',
        :search_field => "journal title"
      }
    end
    config.add_search_field('author/creator',:label => "Author, etc.") do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = {
        :qf => '$author_qf',
        :pf => '$author_pf'
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
    config.add_search_field('call number', :label => 'Call Number') do |field|
#      field.solr_parameters = { :'spellcheck.dictionary' => 'call number' }
      field.include_in_simple_select = true
      field.solr_local_parameters = {
        :qf => '$lc_callnum_qf',
        :pf => '$lc_callnum_pf'
      }
    end
    config.add_search_field('series') do |field|
       field.include_in_simple_select = false
       field.solr_local_parameters = {
         :qf => '$series_qf',
         :pf => '$series_pf'
       }
    end
    config.add_search_field('publisher') do |field|
      # field.solr_parameters = { :'spellcheck.dictionary' => 'callnumber' }
      field.solr_local_parameters = {
        :qf => '$publisher_qf',
        :pf => '$publisher_pf'
      }
    end
    config.add_search_field('place of publication') do |field|
       field.include_in_simple_select = false
       field.solr_local_parameters = {
         :qf => '$pubplace_qf',
         :pf => '$pubplace_pf'
       }
    end
    config.add_search_field('publisher number/other identifier') do |field|
       field.include_in_simple_select = false
       field.solr_local_parameters = {
         :qf => '$number_qf',
         :pf => '$number_pf'
       }
    end
    config.add_search_field('isbn/issn', :label => 'ISBN/ISSN') do |field|
       field.include_in_simple_select = false
       field.solr_local_parameters = {
         :qf => '$isbnissn_qf',
         :pf => '$isbnissn_pf'
       }
    end
    config.add_search_field('notes') do |field|
       field.include_in_simple_select = false
       field.solr_local_parameters = {
         :qf => '$notes_qf',
         :pf => '$notes_pf'
       }
    end
    config.add_search_field('donor name') do |field|
       field.include_in_simple_select = false
       field.solr_local_parameters = {
         :qf => '$donor_qf',
         :pf => '$donor_pf'
       }
    end

    #browse CTS fields. they do not appear in simple or advanced drop downs.
    config.add_search_field('author_pers_browse',:label=>'Author: Personal Name') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'author_pers_browse',
         :pf => 'author_pers_browse'
       }
    end

    config.add_search_field('author_corp_browse', :label=>'Author: Corporate Name') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'author_corp_browse',
         :pf => 'author_corp_browse'
       }
    end

    config.add_search_field('author_event_browse', :label=>'Author: Event') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'author_event_browse',
         :pf => 'author_event_browse'
       }
    end
    config.add_search_field('subject_pers_browse', :label => 'Subject: Personal Name') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'subject_pers_browse',
         :pf => 'subject_pers_browse'
       }
    end

    config.add_search_field('subject_corp_browse', :label => 'Subject: Corporate Name') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'subject_corp_browse',
         :pf => 'subject_corp_browse'
       }
    end

    config.add_search_field('subject_event_browse', :label => 'Subject: Event') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'subject_event_browse',
         :pf => 'subject_event_browse'
       }
    end

    config.add_search_field('subject_topic_browse', :label => 'Subject: Topic Term') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'subject_topic_browse',
         :pf => 'subject_topic_browse'
       }
    end

    config.add_search_field('subject_era_browse', :label => 'Subject: Chronological Term') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'subject_era_browse',
         :pf => 'subject_era_browse'
       }
    end

    config.add_search_field('subject_genr_browse', :label => 'Subject: Genre/Form Term') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'subject_genr_browse',
         :pf => 'subject_genr_browse'
       }
    end

    config.add_search_field('subject_geo_browse', :label => 'Subject: Geographic Name') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'subject_geo_browse',
         :pf => 'subject_geo_browse'
       }
    end

    config.add_search_field('subject_work_browse', :label => 'Subject: Work') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'subject_work_browse',
         :pf => 'subject_work_browse'
       }
    end

    config.add_search_field('authortitle_browse', :label => 'Author (sorted by title)') do |field|
       field.include_in_simple_select = false
       field.include_in_advanced_search = false
       field.solr_local_parameters = {
         :qf => 'authortitle_browse',
         :pf => 'authortitle_browse'
       }
    end

#    config.add_search_field('donor name') do |field|
#       field.include_in_simple_select = false
#       field.solr_parameters = { :qf => '$donor_t' }
#    end
    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
    config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year descending', :include_in_advanced_search => false
    config.add_sort_field 'pub_date_sort asc, title_sort asc', :label => 'year ascending', :include_in_advanced_search => false
    config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author A-Z'
    config.add_sort_field 'author_sort desc, title_sort asc', :label => 'author Z-A'
    config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title A-Z', :browse_default => true
    config.add_sort_field 'title_sort desc, pub_date_sort desc', :label => 'title Z-A'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_check_max = 5
  end

  # Probably there's a better way to do this, but for now we'll make the mollom instance
  # a class variable in order to maintain the connection across CAPTCHA
  # displays and repeated form submissions.
  @@mollom = nil
  # Note: This function overrides the email function in the Blacklight gem found in lib/blacklight/catalog.rb
  # (in order to add Mollom/CAPTCHA integration)
  def email

    @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
    captcha_ok = false

    if request.post?

      # First check to see whether we're here as the result of an attempt to solve a CAPTCHA
      if params[:captcha_response]
        @@mollom ||= Mollom.new({:public_key => ENV['mollom_public_key'], :private_key => ENV['mollom_private_key']})
        captcha_ok = @@mollom.valid_captcha?(:session_id => params[:mollom_session], :solution => params[:captcha_response])
      end

      #
      if params[:to]
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol}
        result = nil
        # Check for valid email address
        if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
          captcha_ok = true #test
          unless captcha_ok
            # Create a new Mollom instance if necessary, then test the message content for spam
            @@mollom ||= Mollom.new({:public_key => ENV['MOLLOM_PUBLIC_KEY'], :private_key => ENV['MOLLOM_PRIVATE_KEY']})
            # Mollom can sometimes fail ('can't get mollom server-list'), so we have to put this next part in a begin/rescue block
            begin
                result = @@mollom.check_content(:author_mail => params[:to], :post_body => params[:message])
                if result.ham?
                    # Content is okay, we can proceed with the email
                    email = RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
                elsif result.spam?
                    # This is definite spam (according to Mollom)
                    flash[:error] = 'Spam!'
                end
            rescue
                # Mollom isn't working, so we'll have to just go ahead and mail the item
                captcha_ok = true
                email = RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params)
            end
          end
        else
          flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
        end
      else
        flash[:error] = I18n.t('blacklight.email.errors.to.blank')
      end

      if !captcha_ok and ((!result.nil? and result.unsure?) or params[:captcha_response])  # i.e., we have to use a CAPTCHA and the user hasn't yet (successfully) submitted a solution
        @captcha = @@mollom.image_captcha
        # Need to pass through the message form elements in order to retain them in the next POST (from CAPTCHA submission)
        @email_params = { :to => params[:to], :message => params[:message], :id => params['id'][0] }
        return render :partial => 'captcha'
      elsif !flash[:error]
        # Don't have to show a CAPTCHA and there are no errors, so we can send the email
        email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :location => params[:location], :callnumber => params[:callnumber], :templocation => params[:templocation], :status => params[:itemStatus]}, url_gen_params, params)
        email.deliver_now
        flash[:success] = "Email sent"
        redirect_to catalog_path(params[:id]) unless request.xhr?
      end

    end  # request.post?

    unless !request.xhr? && flash[:success]
      respond_to do |format|
        format.js { render :layout => false }
        format.html
      end
    end

  end


end
