# -*- encoding : utf-8 -*-
module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      root_path

      
    when /the catalog page/
      #catalog_index_path
      root_path
      
    when /the folder page/
      folder_index_path
         
    when /the document page for id (.+)/ 
      catalog_path($1)
      
    when /the facet page for "([^\"]*)"/
      catalog_facet_path($1)

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end

  def field_to(field_name)
    case field_name

    when /^author$/
      '.blacklight-author_display'
    when /^author_addl_display$/
      '.blacklight-author_addl_display'
    when /^edition$/
      '.blacklight-edition_display'
    when /^notes$/
      '.blacklight-notes'
    when /^pub_info$/
      '.blacklight-pub_info_display'
    when /^subject$/
      '.blacklight-subject_display'
    when /^title$/
      '.blacklight-title_display'
    else
      "#{field_name} did not match a field name in field_to"
    end
  end

  def facet_to(facet) 
    case facet

    when /^format$/
       'blacklight-format'
    when /.*genre$/
       'blacklight-subject_topic_facet'
    when /^language$/
       'blacklight-language_facet'
    when /^call number$/
       'blacklight-lc_1letter_facet'
    when /.*region$/
       'blacklight-subject_geo_facet'
    when /.*era$/
       'blacklight-subject_era_facet'
    when /^location$/
       'blacklight-location_facet'
    when /^publication year$/
       'blacklight-pub_date_facet'
    end
  end

end

World(NavigationHelpers)
