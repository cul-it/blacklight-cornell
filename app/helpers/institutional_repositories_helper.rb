
module InstitutionalRepositoriesHelper

    # https://www.rubydoc.info/gems/bento_search/1.4.2/BentoSearch/ResultItem
    # DLXS: chla, hunt, may, hearth, witchcraft, ezra
    
    def solrResult2Bento(solrIn, resultItem)
        id = solrIn['id']
        if id.starts_with?('ss:')
            return schemeSharedShelf(solrIn, resultItem)
        elsif id.starts_with?('ec:')
            return schemeEcommons(solrIn, resultItem)
        else
            dlxs = ['chla', 'hunt', 'may', 'hearth', 'witchcraft', 'ezra', 'hivebees']
            dlxs.each { |prefix|
                if id.starts_with?(prefix)
                    return schemeDlxs(solrIn, resultItem)
                end
            }
            return 'Unknown Collection Prefix: ' + id
        end
    end

    def schemeSharedShelf(s, r)
        # 'sharedshelf'
        r.title = s['title_tesim'].shift
        if s['creator_tesim'].present?
            r.authors = s['creator_tesim'].clone
        end
        r.abstract = s['collection_tesim'].shift
        if s['date_tesim'].present?
            r.publication_date = s['date_tesim'].shift
        end
    
        if s['media_URL_size_1_tesim'].present?
            r.format_str = s['media_URL_size_1_tesim'].shift
        end
    
        r.link = "http://digital.library.cornell.edu/catalog/#{s['id']}"

        return r
    end

    def schemeDlxs(s, r)
        # 'dlxs'
        r.title = s['title_tesim'].shift
        if s['creator_tesim'].present?
            r.authors = s['creator_tesim'].clone
        end
        r.abstract = 
            if s['collection_tesim'].present?
                s['collection_tesim'].shift
            elsif s['subject_tesim'].present?
                s['subject_tesim'].join(", ")
            else
                ""
            end
        if s['awsthumbnail_tesim'].present?
            r.format_str = s['awsthumbnail_tesim'].pop
        end

        if s['date_tesim'].present?
            r.publication_date = s['date_tesim'].shift
        end
        
        if s['has_model_ssim'].shift == 'Page'
            # pages link to the page reader
            id = s['id']
            parts = id.split("_")
            page = parts.pop
            idprefix = parts.join("_")
            r.link = "http://reader.library.cornell.edu/docviewer/digital?id=#{idprefix}#page/#{page}/mode/1up"
        else
            r.link = "http://digital.library.cornell.edu/catalog/#{s['id']}"
        end

        return r
    end

    def schemeEcommons(s, r)
        # 'ecommons'
        r.title = s['title_tesim'].shift
        if s['creator_tesim'].present?
            r.authors = s['creator_tesim'].clone
        end
        if s['abstract_tesim'].present?
            r.abstract = s['abstract_tesim'].shift
        end
        if s['date_tesim'].present?
            r.publication_date = s['date_tesim'].shift
        end
        r.link = s['handle_tesim'].pop

        return r
    end
end

