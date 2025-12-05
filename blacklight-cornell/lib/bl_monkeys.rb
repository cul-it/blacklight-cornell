module BlacklightMarcHelper

  def render_endnote_xml_texts(documents)
    val = ''

    # :nocov:
      Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__}"
    # :nocov:

    documents.each do |doc|
      tmp = ''
      if doc.exports_as?(:endnote_xml) && !doc.folio_record?
        tmp = doc.export_as(:endnote_xml) + "\n"
        tmp.sub!('<xml>','')
        tmp.sub!('</xml>','')
        tmp.sub!('<records>','')
        tmp.sub!('</records>','')
        val += tmp
      end
    end

    # :nocov:
      Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__} val = #{val}"
    # :nocov:

   "<xml><records> #{val} </records></xml>"
  end

  # puts together a collection of documents into one ris export string
  def render_ris_texts(documents)
    val = ''

    # :nocov:
      Rails.logger.debug"*********es287_dev:#{__FILE__} #{__LINE__} #{__method__}"
    # :nocov:

    documents.each do |doc|
      if doc.exports_as?(:ris) && !doc.folio_record?
        val += doc.export_as(:ris) + "\n"
      end
    end
    val
  end
end

################################################################################
# need not to fail when uri contains |
# This overrides the DEFAULT_PARSER with the UNRESERVED key, including '|'
# DEFAULT_PARSER is used everywhere, so its better to override it once
################################################################################
# June 2025 - updated note from Copilot:
# In Ruby 3.x, URI::Parser.new no longer accepts keyword arguments like :UNRESERVED. 
# The parser is now frozen and expects zero arguments.
# If you need to allow | in URIs:
# Consider replacing | with %7C before parsing, e.g.:
#
# Summary:
#
# The monkey patch is incompatible with Ruby 3.x.
# Remove or comment it out.
# Pre-encode | as %7C if needed.
 module URI
   remove_const :DEFAULT_PARSER
   unreserved = REGEXP::PATTERN::UNRESERVED
   DEFAULT_PARSER = Parser.new(:UNRESERVED => unreserved + "|")
 end

############ need different options on piwik ###################################
module PiwikAnalytics
  module Helpers
    def piwik_tracking_tag_bl
      config = PiwikAnalytics.configuration
      return if config.disabled?
      if config.use_async?
        tag = <<-CODE
        <!-- Piwik -->
        <script type="text/javascript">
        var _paq = _paq || [];
        (function(){
            var u=(("https:" == document.location.protocol) ? "https://#{config.url}/" : "http://#{config.url}/");
            _paq.push(["setDocumentTitle", document.domain + "/" + document.title]);
            _paq.push(["setCookieDomain", "*.library.cornell.edu"]);
             _paq.push(["setDomains", ["*.library.cornell.edu","*.catalog.library.cornell.edu","*.search.library.cornell.edu"]]);
            _paq.push(['setSiteId', #{config.id_site}]);
            _paq.push(['setTrackerUrl', u+'piwik.php']);
            _paq.push(['trackPageView']);
            var d=document,
                g=d.createElement('script'),
                s=d.getElementsByTagName('script')[0];
                g.type='text/javascript';
                g.defer=true;
                g.async=true;
                g.src=u+'piwik.js';
                s.parentNode.insertBefore(g,s);
        })();
        </script>
        <!-- End Piwik Tag -->
        CODE
        tag.html_safe
      else
        tag = <<-CODE
        <!-- Piwik -->
        <script type="text/javascript">
        var pkBaseURL = (("https:" == document.location.protocol) ? "https://#{config.url}/" : "http://#{config.url}/");
        document.write(unescape("%3Cscript src='" + pkBaseURL + "piwik.js' type='text/javascript'%3E%3C/script%3E"));
        </script><script type="text/javascript">
        try {
                var piwikTracker = Piwik.getTracker(pkBaseURL + "piwik.php", #{config.id_site});
                piwikTracker.trackPageView();
                piwikTracker.enableLinkTracking();
        } catch( err ) {}
        </script>
        <!-- End Piwik Tag -->
        CODE
        tag.html_safe
      end
    end
  end
end