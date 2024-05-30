require 'net/http'

class CheckSolrService < StatusPage::Services::Base
  def check!
    solr_config = YAML.load(ERB.new(File.read("#{::Rails.root}/config/blacklight.yml")).result)
    uri = solr_config[ENV['RAILS_ENV']]["url"] unless SOLR_CONFIG.nil? or SOLR_CONFIG[ENV['RAILS_ENV']].nil?

    # Parse the uri and replace the path and query
    uri = URI(uri)
    uri.path = '/solr/admin/cores'
    uri.query = 'action=STATUS'

    url = URI(uri)
    response = Net::HTTP.get_response(url)

    if response.is_a?(Net::HTTPSuccess)
      # Solr is running
      true
    else
      # Solr is not running
      raise "Solr is not running"
    end
  end
end