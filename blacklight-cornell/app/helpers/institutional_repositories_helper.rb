
module InstitutionalRepositoriesHelper

    # https://www.rubydoc.info/gems/bento_search/1.4.2/BentoSearch/ResultItem
    # DLXS: chla, hunt, may, hearth, witchcraft, ezra

    def solrResult2Bento(solrIn, resultItem)

        if solrIn['metadata_structure_tesim'].present? && solrIn['metadata_structure_tesim'].shift == 'oai'
            return schemeOai(solrIn, resultItem)
        else
            id = solrIn['id']
            resultItem.title = solrIn['id']
            resultItem.link = '#'
            resultItem.abstract = 'Unknown metadata structure'
            return resultItem
        end
    end

    def schemeSharedShelf(s, r)
        # 'sharedshelf'
        r.title =
            if s['title_tesim'].present?
                s['title_tesim'].shift
            elsif s['title_ssi'].present?
                s['title_ssi']
            else
                s['id']
            end
        if s['creator_tesim'].present?
            s['creator_tesim'].each { |a| r.authors << BentoSearch::Author.new({:display => a}) }
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
            s['creator_tesim'].each { |a| r.authors << BentoSearch::Author.new({:display => a}) }
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
            s['creator_tesim'].each { |a| r.authors << BentoSearch::Author.new({:display => a}) }
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

    def schemeOai(s, r)
        # 'oai'
        if s['display_target_tesim'].present?

            if s['title_tesim'].present?
                r.title = s['title_tesim'].shift
            else
                r.title = s['id']
            end
            if s['agent_hash_tesim'].present?
                agents = JSON.parse(s['agent_hash_tesim'].shift)
                 agents.each { |a|
                if a[0].present?
                    # production solr
                    agent = a[0]["agent"]
                else
                    # dev solr
                    agent = a["agent"]
                end
                r.authors << BentoSearch::Author.new({:display => agent})
                }
            end

            if s['description_tesim'].present?
                r.abstract = s['description_tesim'].shift
            end

            if s['r1_date_tesim'].present?
                dt = Time.parse(s['r1_date_tesim'].shift)
                r.publication_date = dt.strftime("%Y-%m-%d")
            end

            # Find the link to the item
            if s['id'].start_with?("ec:")
                # ecommons handle
                r.link = 'https://hdl.handle.net/' + s['id'].split(':')[1]
            elsif s['id'].start_with?("ec7:")
                # ecommons handle
                r.link = 'https://hdl.handle.net/' + s['id'].split(':')[1]
            elsif s['r1_identifier_tesim'].present?
                # find an identifier that looks like a link
                ident = s['r1_identifier_tesim']
                ident.each { |i|
                    if (i =~ /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix) == 0
                        r.link = i
                        break
                    end
                }
            end
            if r.link.nil?
                r.link = s['r1_identifier_tesim'].pop
            end
        else
            r.id = s['id']
            r.link = '#'
        end

        return r
    end

    # copied from singlecore - for id:ss\:*
    def set_fq()
        if Rails.env.production?
            fq = 'display_target_tesim:"bento-prod"'
        else
            fq = 'display_target_tesim:"bento"'
        end

    #     if environment == 'development'
    #       fq = '-active_fedora_model_ssi:"Page"
    #       AND -collection_tesim:"Core Historical Library of Agriculture"
    #       AND -solr_loader_tesim:"eCommons"
    #       AND -(collection_tesim:"Cornell Collection of Blaschka Invertebrate Models" AND portal_sequence_isi:[2 TO *])
    #       AND -(collection_tesim:"Seneca Haudenosaunee Archaeological Materials, circa 1688-1754" AND work_sequence_isi:[2 TO *])
    #       AND -(collection_tesim:"Icelandic Stereoscopes" AND work_sequence_isi:[2 TO *])'


    #     elsif environment == 'production'
    #       fq = '(collection_tesim:"Adler Hip Hop Archive"  AND -adler_status:"Suppress for portal")
    #       OR collection_tesim:"Indonesian Music Archive"
    #       OR (-status_ssi:"Unpublished" AND -status_ssi:"Suppressed" AND -active_fedora_model_ssi:"Page" AND -solr_loader_tesim:"eCommons"
    #       AND +(collection_tesim:"New York State Aerial Photographs"
    #       OR collection_tesim:"Huntington Free Library Native American Collection"
    #       OR collection_tesim:"John Reps Collection - Bastides"
    #       OR collection_tesim:"Persuasive Maps: PJ Mode Collection"
    #       OR collection_tesim:"Ragamala Paintings"
    #       OR collection_tesim:"Alfredo Montalvo Bolivian Digital Pamphlets Collection"
    #       OR collection_tesim:"Beyond the Taj: Architectural Traditions and Landscape Experience in South Asia"
    #       OR collection_tesim:"Campus Artifacts, Art & Memorabilia"
    #       OR collection_tesim:"Hip Hop Party and Event Flyers"
    #       OR collection_tesim:"Andrew Dickson White Architectural Photographs Collection"
    #       OR collection_tesim:"Historic Glacial Images of Alaska and Greenland"
    #       OR collection_tesim:"Mysteries at Eleusis: Images of Inscriptions"
    #       OR collection_tesim:"Icelandic and Faroese Photographs of Frederick W.W. Howell"
    #       OR collection_tesim:"Alison Mason Kingsbury: Life and Art"
    #       OR collection_tesim:"John Reps Collection - Urban Explorer"
    #       OR collection_tesim:"John Clair Miller"
    #       OR collection_tesim:"Cornell Coin Collection"
    #       OR collection_tesim:"Cornell Squeeze Collection"
    #       OR collection_tesim:"Billie Jean Isbell Andean Collection"
    #       OR collection_tesim:"Cornell Gem Impressions Collection"
    #       OR collection_tesim:"Punk Flyers"
    #       OR collection_tesim:"Cornell Cast Collection"
    #       OR collection_tesim:"Obama Visual Iconography"
    #       OR collection_tesim:"Loewentheil Collection of African-American Photographs"
    #       OR collection_tesim:"The J. R. Sitlington Sterrett Collection of Archaeological Photographs"
    #       OR collection_tesim:"Selections from the Cornell Anthropology Collections"
    #       OR collection_tesim:"Willard D. Straight in Korea"
    #       OR collection_tesim:"Images from the Rare Book and Manuscript Collections"
    #       OR collection_tesim:"John Clair Miller Image Collection of Twentieth-Century Architecture in Iceland"
    #       OR collection_tesim:"Digitizing Tell en-Naṣbeh, Biblical Mizpah of Benjamin"
    #       OR collection_tesim:"Hill Ornithology Collection"
    #       OR collection_tesim:"Vicos Collection"
    #       OR collection_tesim:"Wordsworth Collection"
    #       OR (collection_tesim:"Cornell Collection of Blaschka Invertebrate Models" AND portal_sequence_isi:1)
    #       OR collection_tesim: "U.S. President\'s Railroad Commission Photographs"
    #       OR collection_tesim: "Political Americana"
    #       OR collection_tesim: "Digital Tamang"
    #       OR collection_tesim: "Kroch Asia Rare Materials Archive"
    #       OR collection_tesim: "Art 2301 Printmaking Student Portfolios"
    #       OR collection_tesim: "Lindsay Cooper Digital Archive"
    #       OR collection_tesim: "International Workers’ Order (IWO) and Jewish People\'s Fraternal Order (JPFO)"
    #       OR collection_tesim: "Depicting the Sri Lankan Vernacular"
    #       OR collection_tesim: "Gail and Stephen Rudin Slavery Collection, 1728-1973"
    #       OR collection_tesim: "19th Century Prison Reform Collection"
    #       OR collection_tesim: "Core Historical Literature of Agriculture"
    #       OR collection_tesim: "Hive & the Honeybee"
    #       OR collection_tesim: "Joe Conzo Jr. Archive"
    #       ))'
    #     end
       end

end

