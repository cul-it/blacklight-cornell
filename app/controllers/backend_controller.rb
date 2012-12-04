class BackendController < ApplicationController
  def holdings
    #@holdings = JSON.parse(HTTPClient.get_content("http://es287-dev.library.cornell.edu:8950/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @holdings = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"))[params[:id]]
    #@holdings_detail = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/retrieve_detail_raw/#{params[:id]}"))[params[:id]]
    #@holdings = JSON.parse(HTTPClient.get_content("http://es287-dev.library.cornell.edu:8950/holdings/fetch/#{params[:id]}"))[params[:id]]
    #@holdings = JSON.parse(HTTPClient.get_content("http://rossini.cul.columbia.edu/voyager_backend/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @id = params[:id]
    logger.debug  "getting info for #{params[:id]} from" 
    logger.debug Rails.configuration.voyager_holdings + "/holdings/retrieve/#{params[:id]}"
    logger.debug @holdings 
    logger.debug session.inspect
    session[:holdings] = @holdings
    #session[:holdings_detail] = @holdings_detail
    logger.debug session.inspect
    if  0 == 1  
      @t = @holdings["holdings"].to_s
      @y = @holdings["holdings"].keys[0].to_s
      @keys = @holdings["holdings"].keys
      #render :text =>  @keys.each { |akey| "Call Number:<b>" + @holdings["holdings"][akey]["call_number"].to_s + "</b> <br/> Library:<b>" +  @holdings["holdings"][akey]["location_name"].to_s + "</b><br/>" }  
      @txt = "" 
      @entries=[];
      @keys.each  do |akey|  
            @items = @holdings["holdings"][akey]["items"]
            @is = "" 
            @items.each  do |aItem|  
              @is = @is + ' ' + 
        ( aItem["copy_number"].empty? ? "" :
       ' copy ' + aItem["copy_number"]  ) +  ' ' + aItem["desc"] 
            end 
            @entries << {"call_number" => @holdings["holdings"][akey]["call_number"],"location_name" => @holdings["holdings"][akey]["location_name"], "status"=>@is.to_str } 
            @txt = @txt + "<hr/><pre>Callnumber:" + @holdings["holdings"][akey]["call_number"].to_s + "<br/>Library:" +  @holdings["holdings"][akey]["location_name"].to_s + @is.to_str + "<br/></pre>"
    end
    end 
    #render :text => @txt.to_s  + @t.to_s
    render "backend/holdings", :layout => false
  end

  def holdings_mail

    @holdings = JSON.parse(HTTPClient.get_content("http://rossini.cul.columbia.edu/voyager_backend/holdings/retrieve/#{params[:id]}"))[params[:id]]
    @id = params[:id]

    render "backend/_holdings_mail", :layout => false
  end

  def feedback_mail
    session[:feedback_form_name] = params["name"]
    session[:feedback_form_email] = params["email"]
    begin
      FeedbackNotifier.send_feedback(params).deliver
  
      render :text => "success"
    rescue Exception => e
      logger.info e.backtrace
      render :text => "failure"
    end
  end

  def retrieve_book_jackets
    isbns = params["isbns"].listify
    results = {}
    hc = HTTPClient.new

    begin
      isbns.each do |isbn|
        unless results[isbn]
          query_url = 'http://books.google.com/books/feeds/volumes'
          logger.info("retrieving #{query_url}?q=isbn:#{isbn}")
          xml = Nokogiri::XML(hc.get_content(query_url, :q => "isbn:" + isbn))
          image_node = xml.at_css("feed>entry>link[@type^='image']")
          results[isbn] = image_node.attributes["href"].content.gsub(/zoom=./,"zoom=1") if image_node
        end
      end
    rescue Exception => e
      logger.warn("exception retrieving google book search: #{e.message}")
    end
    
    render :json => results
  end


end
