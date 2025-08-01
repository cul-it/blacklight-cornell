# -*- encoding : utf-8 -*-
class CatalogController < ApplicationController

  include BlacklightRangeLimit::ControllerOverride
  include Blacklight::Catalog

#  include Blacklight::SearchHelper
  include BlacklightCornell::CornellCatalog
  include Blacklight::DefaultComponentConfiguration
  include BlacklightUnapi::ControllerExtension
  include Blacklight::Marc::Catalog
  require 'rest-client'
  require 'cul/folio/edge'

  if   ENV['SAML_IDP_TARGET_URL']
    before_action :authenticate_user!, only: [  :email ]
    #prepend_before_action :set_return_path
  end

  #  DACCESS-215
  def index
    if query_has_pub_date_facet? && !params.key?(:q)
      redirect_to params.merge(q: '')
    else
      super
    end
  end

  def repository_class
    Blacklight::Solr::Repository
  end
  unless  ENV['SAML_IDP_TARGET_URL']
    before_action :authorize_email_use!, only: :email
  end

  # This is used to protect the email function by limiting it to only Cornell
  # users. If not signed in, the user is prompted to click a link that redirects
  # through a CUWebAuth-protected route. The partial that's rendered doesn't
  # seem to actually appear anywhere (not sure why), but rendering 'nothing'
  # instead doesn't let the email modal appear either.
  def authorize_email_use!
    if  !session[:cu_authenticated_user].present?
        flash[:error] = "You must <a href='/backend/cuwebauth'>login with your Cornell NetID</a> to send email.".html_safe
      # This is a bit of an ugly hack to get us back to where we started after
      # the authentication
      session[:send_email_on_catalog_item_load] = (params['id'].present? && params['id'].include?('|')) ? false : true
      session[:cuwebauth_return_path] = (params['id'].present? && params['id'].include?('|')) ? '/bookmarks' : "/catalog/#{params[:id]}"
      render :partial => 'catalog/email_cuwebauth'
    end
  end

  before_action :redirect_browse

  configure_blacklight do |config|
    # chris beer recommended for latest version of unapi
    config.unapi = {
      'oai_dc_xml' => { :content_type => 'text/xml' }
    }
    config.index.partials << 'microformat'
    config.show.partials << 'microformat'
    # end of unapi config.

    ## Should the raw solr document endpoint (e.g. /catalog/:id/raw) be enabled
    config.raw_endpoint.enabled = true

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      :qt => 'search',
      :rows => 20,
# DISCOVERYACCESS-1472      :fl => '*,score',
# Look into removing :fl entirely during off sprint
      :defType => 'edismax',
      :"f.lc_callnum_facet.facet.limit" => "-1"
    }

    ## list of display fields with icon
    config.display_icon = {
        'format' => 1
    }

    config.per_page = [20,50,100]

    ## list of clickable display fields mapped to target index field
    ## target index field should be defined in add_search_field later this file
    ## target index field is searched when this link is clicked
    config.display_clickable = {

        'included_work_display' => {
           :search_field => 'title',
           :related_search_field => 'author',
           :sep => '|',
           :key_value => true,
           :related_auth_field => 'authortitle_facet'
        },
        'related_work_display' => {
            :search_field => 'title',
            :related_search_field => 'author',
            :sep => '|',
            :key_value => true
        },
        'author_json' => {
            :search_field => 'author_cts',
            :sep => '|',
            :sep_display => ' / ',
            :pair_list_json => true
        },
        'author_addl_json' => {
            :search_field => 'author_cts',
            :sep => '|',
            :sep_display => ' / ',
            :pair_list_json => true
        },
        'title_series_cts' => {
          :search_field => 'series',
          :sep => '|',
          :key_value => true
        },
        'subject_json' => {
            :search_field => 'subject_cts',
            :sep => '|',
            :sep_index => ' > ',
            :sep_display => ' > ',
            :json => true
        },
        'title_uniform_display' => {
            :search_field => 'title',
            :related_search_field => 'author',
            :sep => '|',
            :key_value => true
        },
    }

    config.display_link = {
        'url_other_display'  => { :label => 'Other online content' },
        'url_bookplate_display'  => { :label => 'Bookplate' },
        'url_findingaid_display'  => { :label => 'Finding Aid' },
        'other_availability_piped'  => { :label => 'Other Availability' }

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
    config.default_document_solr_params = { #}
      :qt => 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #  # :fl => '*',
    #  # :rows => 1
    #  # :q => '{!raw f=id v=$id}'
    }
    config.document_solr_path = 'select'
    config.document_unique_id_param = 'id'

    # solr field configuration for search results/index views
    config.index.title_field = 'fulltitle_display', 'fulltitle_vern_display' #display as 'fulltitle_vern / title : subtitle'
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
    #if  RAILS_ENV = 'development'
    #config.add_facet_field 'availability_facet', :label => 'Availability Status', :limit => 30, :collapse => false
    #end
    config.add_facet_field 'online', :label => 'Access', :limit => 2, :collapse => false
    config.add_facet_field 'format',
                           label: 'Format',
                           limit: 10,
                           collapse: false,
                           include_in_advanced_search: true,
                           advanced_search_order: 1,
                           sort: 'count'
    config.add_facet_field 'author_facet', :label => 'Author, etc.', :limit => 5, if: :has_search_parameters?
    config.add_facet_field 'pub_date_facet',
                           label: 'Publication Year',
                           range: true,
                           range_config: {
                             num_segments: 6,
                             segments: true
                           },
                           show: true,
                           include_in_advanced_search: true,
                           if: :has_search_parameters?,
                           advanced_search_component: AdvancedRangeLimitComponent,
                           advanced_search_order: 0

    config.add_facet_field 'workid_facet', :label => 'Work', :show => false
    config.add_facet_field 'language_facet',
                           label: 'Language',
                           limit: 5,
                           show: true,
                           include_in_advanced_search: true,
                           advanced_search_order: 2,
                           sort: 'count'
    config.add_facet_field 'fast_topic_facet', :label => 'Subject', :limit => 5, if: :has_search_parameters?
    config.add_facet_field 'fast_geo_facet', :label => 'Subject: Region', :limit => 5, if: :has_search_parameters?
    config.add_facet_field 'fast_era_facet', :label => 'Subject: Era', :limit => 5, if: :has_search_parameters?
    config.add_facet_field 'fast_genre_facet', :label => 'Genre', :limit => 5, if: :has_search_parameters?
    config.add_facet_field 'subject_content_facet', :label => 'Fiction/Non-Fiction', :limit => 5, if: :has_search_parameters?
    config.add_facet_field 'lc_alpha_facet', :label => 'Call Number', :limit => 5, :show => false
    #config.add_facet_field 'location_facet', :label => 'Library Location', :limit => 5
    config.add_facet_field 'location',
                          label: 'Library Location',
                          component: Blacklight::Hierarchy::FacetFieldListComponent,
                          sort: 'index',
                          limit: 100
    config.add_facet_field 'hierarchy_facet', :hierarchy => true
    config.add_facet_field 'authortitle_facet', :show => false, :label => "Author-Title"
    config.add_facet_field 'lc_callnum_facet',
                           if: :has_search_parameters?,
                          label: 'Call Number',
                          component: Blacklight::Hierarchy::FacetFieldListComponent,
                          sort: 'count'


   config.facet_display = {
     :hierarchy => {
       'lc_callnum' => [['facet'], ':'],
       'location' => [[nil],' > ']
     }
 }

    config.add_facet_field 'collection', :show => false


    config.add_facet_field 'acquired_dt_query',  label: 'Date Acquired', query: {
      last_1_week: { label: 'Since last week', fq: "acquired_dt:[NOW-14DAY TO NOW-7DAY]"},
      last_1_month: { label: 'Since last month', fq: "acquired_dt:[NOW-30DAY TO NOW-7DAY]"},
      last_1_years: { label: 'Since last year', fq: "acquired_dt:[NOW-1YEAR TO NOW-7DAY]"}
    }, if: :has_search_parameters?


    # config.add_facet_field 'facet', :multiple => true
    # config.add_facet_field 'first_facet,last_facet', :pivot => ['first_facet', 'last_facet']
    # config.add_facet_field 'my_query_field', :query => { 'label' => 'value:1', 'label2' => 'value:2'}
    # config.add_facet_field 'facet', :single => true
    # config.add_facet_field 'facet', :tag => 'my_tag', :ex => 'my_tag'

    #config.default_solr_params[:'facet.field'] = config.facet_fields.keys
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
    config.add_index_field 'pub_date_display', :label => 'Publication date'
    config.add_index_field 'pub_info_display', :label => 'Publication'
    config.add_index_field 'edition_display', :label => 'Edition', :helper_method => :render_single_value

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # These title related fields called directly in _show_metadata partial
    # -- title_display
    # -- title_vern_display
    # -- subtitle_display
    # -- subtitle_vern_display
    config.add_show_field 'title_uniform_display', :label => 'Uniform title'
    config.add_show_field 'author_json', :label => 'Author, etc.'
    config.add_show_field 'format', :label => 'Format', :helper_method => :render_show_format_value, separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
    config.add_show_field 'language_display', :label => 'Language'
    config.add_show_field 'edition_display', :label => 'Edition'
    config.add_show_field 'pub_info_display', :label => 'Published'
    config.add_show_field 'pub_prod_display', :label => 'Produced'
    config.add_show_field 'pub_dist_display', :label => 'Distributed'
    config.add_show_field 'pub_manu_display', :label => 'Manufactured'
    config.add_show_field 'pub_copy_display', :label => 'Copyright date'
    config.add_show_field 'publisher_number_display', :label => 'Publisher number'
    config.add_show_field 'doi_display', :label => 'DOI'
    config.add_show_field 'cite_as_display', :label => 'Cite as'
    config.add_show_field 'historical_note_display', :label => 'Biographical/ Historical note'
    config.add_show_field 'finding_aids_display', :label => 'Finding aid'
    config.add_show_field 'subject_json', :label => 'Subject'
    config.add_show_field 'keyword_display', :label => 'Keyword'
    config.add_show_field 'summary_display', :label => 'Summary', helper_method: :html_safe
    config.add_show_field 'description_display', :label => 'Description', helper_method: :html_safe
    config.add_show_field 'issn_display', :label => 'ISSN'
    config.add_show_field 'isbn_display', :label => 'ISBN'
    config.add_show_field 'frequency_display', :label => 'Frequency'
    config.add_show_field 'author_addl_json', :label => 'Other contributor'
    config.add_show_field 'contents_display', :label => 'Table of contents', helper_method: :contents_list
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
    config.add_show_field 'merger_of_display', :label => 'Merger of'
    config.add_show_field 'translation_of_display', :label => 'Translation of'
    config.add_show_field 'has_translation_display', :label => 'Has translation'
    config.add_show_field 'other_edition_display', :label => 'Other edition'
    config.add_show_field 'indexed_selectively_by_display', :label => 'Indexed selectively by'
    config.add_show_field 'indexed_by_display', :label => 'Indexed By'
    config.add_show_field 'references_display', :label => 'References'
    config.add_show_field 'indexed_in_its_entirety_by_display', :label => 'Indexed in its entirety by'
    config.add_show_field 'in_display', :label => 'In'
    config.add_show_field 'map_format_display', :label => 'Map format'
    config.add_show_field 'instrumentation_display', :label => 'Instrumentation'
    config.add_show_field 'has_supplement_display', :label => 'Has supplement'
    config.add_show_field 'supplement_to_display', :label => 'Supplement to'
    config.add_show_field 'other_form_display', :label => 'Other form'
    config.add_show_field 'issued_with_display', :label => 'Issued with'
    config.add_show_field 'separated_from_display', :label => 'Separated from'
    config.add_show_field 'cast_display', :label => 'Cast'
    config.add_show_field 'notes', :label => 'Notes', separator_options: { words_connector: '<br />', last_word_connector: '<br />' }
    config.add_show_field 'thesis_display', :label => 'Thesis'
    config.add_show_field 'indexes_display', :label => 'Indexes'
    config.add_show_field 'donor_display', :label => 'Donor'
    config.add_show_field 'former_owner_display', :label => 'Former Owner'
    config.add_show_field 'url_bookplate_display', :label => 'Bookplate'
    config.add_show_field 'url_other_display', :label => 'Other online content'
    config.add_show_field 'works_about_display', :label => 'Works about'
    config.add_show_field 'awards_display', :label => 'Awards'
    # config.add_show_field 'holdings_json', :label => 'Holdings'



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

    config.add_search_field('all_fields') do |field|
      field.label = 'All Fields'
      field.include_in_advanced_search = true
      field.field_override = ''
      field.phrase_field = 'phrase'
      field.quoted_field = 'quoted'
      field.starts_field = 'starts'
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field 'separator_1', label: '---', include_in_advanced_search: false

    config.add_search_field('title') do |field|
      field.label = 'Title'
      field.phrase_field = 'title_phrase'
      field.quoted_field = 'title_quoted'
      field.starts_field = 'title_starts'

      # solr_parameters hash are sent to Solr as ordinary url query params.
      # field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      # field.solr_local_parameters = {
      #   :qf => '$title_qf',
      #   :pf => '$title_pf'
      # }
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
    config.add_search_field('journaltitle') do |field|
      field.label = 'Journal Title'
      field.field_override = 'title'
      field.phrase_field = 'title_phrase'
      field.quoted_field = 'title_quoted'
      field.starts_field = 'title_starts'
      field.format = 'Journal/Periodical'
    end

    config.add_search_field('title_starts') do |field|
      field.label = 'Title Begins With'
      field.include_in_simple_select = true
      field.include_in_advanced_search = false
    end

    config.add_search_field 'separator_2', label: '---', include_in_advanced_search: false

    config.add_search_field('author') do |field|
      field.label = 'Author'
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.quoted_field = 'author_quoted'
      field.starts_field = 'author_starts'
    end

    # add browse searches to simple search trying to get merged
    config.add_search_field('author_browse') do |field|
      field.include_in_advanced_search = false
      field.label = 'Author Browse (A-Z) Sorted By Name'
      field.placeholder_text = 'Dickens, Charles'
    end

    config.add_search_field('at_browse') do |field|
      field.label = 'Author Browse (A-Z) Sorted By Title'
      field.include_in_advanced_search = false
      field.placeholder_text = 'Beethoven, Ludwig van, 1770-1827 | Fidelio'
    end

    config.add_search_field 'separator_3', :label => '---', :include_in_advanced_search => false

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject', :label => "Subject") do |field|
      field.qt = 'search'
      field.quoted_field = 'subject_quoted'
      field.starts_field = 'subject_starts'
    end

    config.add_search_field('subject_browse') do |field|
      field.label = 'Subject Browse (A-Z)'
      field.include_in_advanced_search = false
      field.placeholder_text = 'China > History'
    end

    config.add_search_field 'separator_4', label: '---', include_in_advanced_search: false

    config.add_search_field('lc_callnum') do |field|
      field.label = 'Call Number'
      field.include_in_simple_select = true
      field.solr_local_parameters = {
        qf: '$lc_callnum_qf',
        pf: '$lc_callnum_pf',
      }
      field.starts_field = 'lc_callnum_starts'
    end

    config.add_search_field('callnumber_browse') do |field|
      field.label = 'Call Number Browse'
      field.include_in_advanced_search = false
      field.placeholder_text = 'TP640'
    end

    config.add_search_field('series') do |field|
      field.include_in_simple_select = false
      field.solr_local_parameters = {
        qf: '$series_qf',
        pf: '$series_pf'
      }
      field.quoted_field = 'series_quoted'
      field.starts_field = 'series_starts'
    end

    config.add_search_field('publisher') do |field|
      field.quoted_field = 'publisher_quoted'
      field.starts_field = 'publisher_starts'
    end

    config.add_search_field('pubplace') do |field|
      field.label = 'Place of Publication'
      field.include_in_simple_select = false
      field.quoted_field = 'pubplace_quoted'
      field.starts_field = 'pubplace_starts'
    end

    config.add_search_field('number') do |field|
      field.label = 'Publisher Number/Other Identifier'
      field.include_in_simple_select = false
      field.phrase_field = 'number_phrase'
      field.quoted_field = 'number_quoted'
      field.starts_field = 'number_starts'
    end

    config.add_search_field('isbnissn') do |field|
      field.label = 'ISBN/ISSN'
      field.include_in_simple_select = false
      field.quoted_field = 'isbnissn_quoted'
      field.starts_field = 'isbnissn_starts'
    end

    config.add_search_field('notes') do |field|
      field.include_in_simple_select = false
      field.quoted_field = 'notes_quoted'
      field.starts_field = 'notes_starts'
    end

    config.add_search_field('donor') do |field|
      field.label = 'Donor/Provenance'
      field.include_in_simple_select = false
      field.quoted_field = 'donor_quoted'
      field.starts_field = 'donor_starts'
    end

    #config.add_search_field('acquired_month') do |field|
    #  field.include_in_simple_select = true
    #  field.solr_local_parameters = {
    #    :qf => '$acquired_month_qf',
    #    :pf => '$acquired_month_pf'
    #  }
    #end
    #config.add_search_field('acquired_dt') do |field|
    #  field.include_in_simple_select = false
    #  field.solr_local_parameters = {
    #    :qf => '$acquired_dt_qf',
    #    :pf => '$acquired_dt_pf'
    #  }
    #end

    # Combined author CTS (Click to Search) field made from the multiple author browse fields
    # Linked from catalog record pages
    config.add_search_field('author_cts') do |field|
      field.label = 'Author/Contributor'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    # Combined subject CTS field made from the multiple subject browse fields
    # Linked from catalog record pages
    config.add_search_field('subject_cts') do |field|
      field.label = 'Subject'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    # Browse CTS fields linked to from the browse info pages
    config.add_search_field('author_pers_browse') do |field|
      field.label = 'Author: Personal Name'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('author_corp_browse') do |field|
      field.label = 'Author: Corporate Name'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('author_event_browse') do |field|
      field.label = 'Author: Event'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('subject_pers_browse') do |field|
      field.label = 'Subject: Personal Name'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('subject_corp_browse') do |field|
      field.label = 'Subject: Corporate Name'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('subject_event_browse') do |field|
      field.label = 'Subject: Event'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('subject_topic_browse') do |field|
      field.label = 'Subject: Topic Term'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('subject_era_browse') do |field|
      field.label = 'Subject: Chronological Term'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('subject_genr_browse') do |field|
      field.label = 'Subject: Genre/Form Term'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('subject_geo_browse') do |field|
      field.label = 'Subject: Geographic Name'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('subject_work_browse') do |field|
      field.label = 'Subject: Work'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

    config.add_search_field('authortitle_browse') do |field|
      field.label = 'Author (sorted by title)'
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
    end

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
    config.add_sort_field 'callnum_sort asc, pub_date_sort desc', :label => 'call number', :callnum_default => true
    config.add_sort_field 'acquired_dt desc, title_sort asc', :label => 'date acquired'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_check_max = false
  end

  # Probably there's a better way to do this, but for now we'll make the mollom instance
  # a class variable in order to maintain the connection across CAPTCHA
  # displays and repeated form submissions.
  @@mollom = nil


  def afemail
    @id = params[:id]
    docs = params[:id].split '|'
    @response, @documents = search_service.fetch docs
    dox = {to: "jgr25@cornell.edu", message: "your stuff", callnumber:  @id}
    email_action(dox)
    # , to: "jgr25@cornell.edu", message: "your stuff", :callnumber => docs

    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
  end

  def logins
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
  end

  # Note: This function overrides the email function in the Blacklight gem found in lib/blacklight/catalog.rb
  # (in order to add Mollom/CAPTCHA integration)
  # but now we removed mollom captcha.
#  def email
#    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params  = #{params.inspect}")
#    docs = params[:id].split '|'
#    @response, @documents = search_service.fetch docs
#    if request.post?
#      url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
#      if params[:to] && params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
#        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
#        email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
#        email.deliver_now
#        flash[:success] = "Email sent"
#        redirect_to solr_document_path(params[:id]) unless request.xhr?
#      else
#          flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
#      end
#    end
#
#    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  request.xhr?  = #{request.xhr?.inspect}")
#    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  flash  = #{flash.inspect}")
#    if   ENV['SAML_IDP_TARGET_URL']
#      if request.xhr? && flash[:success]
#        if docs.size < 2
#          render :js => "window.location = '/catalog/#{params[:id]}'"
#        else
#          render :js => "window.location = '/bookmarks'"
#        end
#        return
#      end
#    end
#    unless !request.xhr? && flash[:success]
#      respond_to do |format|
#        format.js { render :layout => false }
#        format.html
#      end
#    end
#  end

  # Note: This function overrides the email function in the Blacklight gem found in lib/blacklight/catalog.rb
  # (in order to add Mollom/CAPTCHA integration)
  def mollom_email

    Rails.logger.debug "mjc12test: entering email"
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params  = #{params.inspect}")

    # If multiple documents are specified (i.e., these are a list of bookmarked items being emailed)
    # then they will be passed into params[:id] in the form "bibid1/bibid2/bibid3/etc"
    #docs = params[:id].split '/'
    docs = params[:id].split '|'

    #@response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
    @response, @documents = fetch docs

    #Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  response = #{@response.inspect}")
    #Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  documents = #{@documents.inspect}")
    captcha_ok = false

    if request.post?
      # First check to see whether we're here as the result of an attempt to solve a CAPTCHA
      if params[:captcha_response]
        begin
           @@mollom ||= Mollom.new({:public_key => ENV['MOLLOM_PUBLIC_KEY'], :private_key => ENV['MOLLOM_PRIVATE_KEY']})
           captcha_ok = @@mollom.valid_captcha?(:session_id => params[:mollom_session], :solution => params[:captcha_response])
        rescue
          captcha_ok = true
          url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
          email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
        end

      end

      #
      if params[:to]
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
      #  result = nil
        # Check for valid email address
        if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
         # captcha_ok = false #test
          unless captcha_ok
            # Create a new Mollom instance if necessary, then test the message content for spam
            @@mollom ||= Mollom.new({:public_key => ENV['MOLLOM_PUBLIC_KEY'], :private_key => ENV['MOLLOM_PRIVATE_KEY']})
            # Mollom can sometimes fail ('can't get mollom server-list'), so we have to put this next part in a begin/rescue block
            begin
                result = @@mollom.check_content(:author_mail => params[:to], :post_body => params[:message])
                if result.ham?
                    # Content is okay, we can proceed with the email
                    email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
                elsif result.unsure? || result.spam? #spam?
                    # This is definite spam (according to Mollom)
                  #  captcha_ok = false
                    flash[:error] = 'Spam!'
                  #  return
                end
            rescue
                # Mollom isn't working, so we'll have to just go ahead and mail the item
                captcha_ok = true
                email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
            end
          end
        else
          flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
        end
      else
        flash[:error] = I18n.t('blacklight.email.errors.to.blank')
      end

      if !captcha_ok and ((!result.nil? and (result.unsure? || result.spam?)) or params[:captcha_response])  # i.e., we have to use a CAPTCHA and the user hasn't yet (successfully) submitted a solution
        @captcha = @@mollom.image_captcha
        # Need to pass through the message form elements in order to retain them in the next POST (from CAPTCHA submission)
        @email_params = { :to => params[:to], :message => params[:message], :id => params['id'], :params => params }
         flash[:error] = 'Spam!'
        return render :partial => 'catalog/captcha'
      elsif !flash[:error]
        # Don't have to show a CAPTCHA and there are no errors, so we can send the email
        email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :location => params[:location], :callnumber => params[:callnumber],
                                                         :templocation => params[:templocation], :status => params[:itemStatus], :params => params}, url_gen_params, params)
        email.deliver_now
        flash[:success] = "Email sent"
        Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} emailing   = #{flash.inspect}")
        redirect_to solr_document_path(params[:id]) unless request.xhr?
      end

    end  # request.post?
    if false
      unless !request.xhr? && flash[:success]
        respond_to do |format|
          format.js { render :layout => false }
          format.html
        end
      end
    end
end

def tou
    clnt = HTTPClient.new
    #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
    solr = Blacklight.connection_config[:url]
    p = {"id" =>params[:id] , "wt" => 'json',"indent"=>"true"}
    @dbString = clnt.get_content("#{solr}/termsOfUse?"+p.to_param)
    @dbResponse = JSON.parse(@dbString)
    @db = @dbResponse['response']['docs'][0]
    @dbString2 = clnt.get_content("#{solr}/select?qt=search&fl=*&q=id:#{params[:id]}")
    @dbResponse2 = JSON.parse(@dbString2)
    @db2 = @dbResponse2['response']['docs'][0]
    @dblinks = @dbResponse['response']['docs'][0]['url_access_json']
    if @dbResponse['response']['numFound'] == 0
        @defaultRightsText = ''
        return @defaultRightsText
    else
        @dblinks.each do |link|
            l = JSON.parse(link)
            if l["providercode"] == params[:providercode] && l["dbcode"] == params[:dbcode]
                @defaultRightsText = ''
                @ermDBResult = ::Erm_data.where(SSID: l["ssid"], Provider_Code: l["providercode"], Database_Code: l["dbcode"], Prevailing: 'true')
                if @ermDBResult.size < 1
                   @ermDBResult = ::Erm_data.where(SSID: l["ssid"], Provider_Code: l["providercode"], Prevailing: 'true')
                   if @ermDBResult.size < 1
                      @ermDBResult = ::Erm_data.where(Database_Code: l["dbcode"], Provider_Code: l["providercode"], Prevailing: 'true')
                      if @ermDBResult.size < 1
                         @ermDBResult = ::Erm_data.where(Provider_Code: l["providercode"], Prevailing: 'true', Database_Code:  '' )
                         if @ermDBResult.size < 1
                                  #   @defaultRightsText = "DatabaseCode and ProviderCode returns nothing"
                                  @defaultRightsText = "Use default rights text"
                         else
                           @db = [l]
                           #return @ermDBResult
                           break
                         end
                      else
                        @db = [l]
                       break
                      end
                   else
                     @db = [l]
                     break
                   end
                else
                  @db = [l]
                  break
                end
            end
            @db = [l]
        end
    @column_names = ::Erm_data.column_names.collect(&:to_sym)
    end

  end

  # TODO: mjc12: I don't understand why we have two functions for TOU: tou and new_tou. The former gets TOU info from
  # Solr, the latter from FOLIO. Why do we have two sources of metadata?
  def new_tou
    packageName = ""
    title_id = params[:title_id]
    id = params[:id]
    @newTouResult = []
    # okapi_url = ENV['OKAPI_URL']
    record = eholdings_record(title_id) || []
    if record
      # recordTitle = record["data"]["attributes"]["name"]
      record["included"].each do |package|
        attrs = package['attributes']
        if attrs["isSelected"] == true
          packageID = attrs["packageId"]
          packageName = attrs["packageName"]
          # packageUrl = attrs["url"]
          # package_providerID = attrs["providerName"]
          subscription = subscription_agreements(packageID)
          if subscription.present?
            if subscription[0]["linkedLicenses"][0]
              remoteID = subscription[0]["linkedLicenses"][0]["remoteId"]
              license = license(remoteID)
              if license
                license['packageName'] = packageName
                @newTouResult << license unless @newTouResult.any? {|h| h["id"] == license['id']}
              end
            end
          end
        end
      end
    end

    @newTouResult
  end

  def eholdings_record(id)
    # eholdings title JSON response described here:
    # https://s3.amazonaws.com/foliodocs/api/mod-kb-ebsco-java/r/titles.html#eholdings_titles_get
    folio_request("#{ENV['OKAPI_URL']}/eholdings/titles/#{id}?include=resources")
  end

  # Make a FOLIO request to retrieve an array of subscription agreements linked to an e-holdings record
  # specified by id.
  def subscription_agreements(id)
    folio_request("#{ENV['OKAPI_URL']}/erm/sas?filters=items.reference=#{id}&sort=startDate:desc")
  end

  # Make a FOLIO request to retrieve a license object linked to an e-holdings record
  # specified by id ('remoteId' in the JSON).
  def license(id)
    folio_request("#{ENV['OKAPI_URL']}/licenses/licenses/#{id}")
  end

  # Given a URL, make a FOLIO request and return the results (or nil in case of a RestClient exception).
  def folio_request(url)
    token = folio_token
    if url && token
      headers = {
        'X-Okapi-Tenant' => ENV['OKAPI_TENANT'],
        'x-okapi-token' => token,
        :accept => 'application/json, application/vnd.api+json'
      }
      response = RestClient.get(url, headers)
      JSON.parse(response.body) if response && response.code == 200
    end
  rescue RestClient::ExceptionWithResponse => err
    Rails.logger.error "TOU: Error making FOLIO request (#{err})"
    nil
  end

  # Return a FOLIO authentication token for API calls -- either from the session if a token
  # was prevoiusly created, or directly from FOLIO otherwise.
  #
  # TODO: Caching is being disabled for now, since it's causing problems with the new expiring
  # token mechanism in FOLIO. We need to figure out how to cache the token properly. (mjc12)
  def folio_token
   #  if session[:folio_token].nil?
      url = ENV['OKAPI_URL']
      tenant = ENV['OKAPI_TENANT']
      response = CUL::FOLIO::Edge.authenticate(url, tenant, ENV['OKAPI_USER'], ENV['OKAPI_PW'])
      if response[:code] >= 300
        Rails.logger.error "TOU error: Could not create a FOLIO token for #{user}"
      else
        session[:folio_token] = response[:token]
      end
   #  end
    session[:folio_token]
  end

  #def oclc_request
  #  Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{params[:id].inspect}")
  #end

  def redirect_browse
    if params[:search_field] && params[:controller] != 'advanced'
      if params[:search_field] == 'subject_browse' && !params[:id]
        redirect_to "/browse?authq=#{CGI.escape params[:q]}&start=0&browse_type=Subject"
      elsif params[:search_field] == 'author_browse' && !params[:id]
        redirect_to "/browse?authq=#{CGI.escape params[:q]}&start=0&browse_type=Author"
      elsif params[:search_field] == 'at_browse' && !params[:id]
        redirect_to "/browse?authq=#{CGI.escape params[:q]}&start=0&browse_type=Author-Title"
      elsif params[:search_field] == 'callnumber_browse' && !params[:id]
        redirect_to "/browse?authq=#{CGI.escape params[:q]}&start=0&browse_type=Call-Number"
      end
    end
  end

#  def range_limit
#    redirect_to "/"
#  end

  # https://bibwild.wordpress.com/2019/04/30/blacklight-7-current_user-or-other-request-context-in-searchbuilder-solr-query-builder/
  def search_service_context
    {
      current_user: current_user
    }
  end

end
