# -*- encoding : utf-8 -*-
# Then /^I should see a search field$/ do
#   page.should have_selector("input#q")
# end

Then /^I should see a bento "([^\"]*)" button$/ do |label|
  #page.should have_selector('button#search-btn')
  page.should have_selector('input[value="Search"]')
end

Then /^I should get bento results$/ do
  page.should  have_selector('.bento1')
  bento1 = all('.bento1')[0].text
  bento1.should match(/[a-zA-Z]+/) 
end

Then /^I should not get bento results$/ do
  if false 
    anytext= all('.bento1')[0].text
    anytext.should_not match(/[a-zA-Z]+/)
  else
    page.should_not have_selector('.bento1')
  end
end

Then(/^facet "(.*?)" should match "(.*?)" (nth|th|rd|st|nd) "(.*?)" in "(.*?)"$/) do |label,nth,nstr,type,divtag|
     total = all('.view-all')[nth.to_i]
     total.should have_content(type) 
     #print "total on bento box page is #{total.text}\n"
     num = total.text.match(/([0-9,]+)/)[0]
     #print "#{__FILE__} #{__LINE__} num is #{num}\n"
     l2 = find('#' + label)
     href =  l2[:href]
     if type.match("from Catalog")
       cmd =  "wget -O -  '#{href}' 2>/dev/null"
       page2 = `#{cmd}`
      sleep 3
       pagedom = Nokogiri::HTML(page2)   
       pagedom.css('.'+divtag)[0].should_not be_nil 
       numx = pagedom.css('.'+divtag)[0].text 
       #print "total2 on view all page is #{numx}\n"
       numx.should_not be_nil
       numx.match(/of\s+(\d+)/).should_not be_nil
       numx.match(/of\s+(\d+)/)[1].should_not be_nil
       num2 = numx.match(/of\s+(\d+)/)[1]
     else
       visit(href)
      sleep 3
       total2 = find('.'+divtag,match: :first)
       total2.should_not be_nil
       num2 = total2.text.match(/of ([0-9,]+) /)[1]
     end
     num.should_not be_nil
     num2.should_not be_nil
     num2.gsub!(',','')
     num.gsub!(',','')
     diff = (num2.to_i - num.to_i).abs
     diff.should <=(30)
end

Then(/^box "(.*?)" should match "(.*?)" (nth|th|rd|st|nd) "(.*?)" in "(.*?)"$/) do |label,nth,nstr,type,divtag|
  
  total = all('.view-all')[nth.to_i]
  total.should have_content(type) 
  #print "total on bento box page is #{total.text}\n"
  num = total.text.match(/([0-9,]+)/)[0]
  #print "#{__FILE__} #{__LINE__} num is #{num}\n"
  #print "#{__FILE__} #{__LINE__} type is #{type}\n"
  #print "#{__FILE__} #{__LINE__} label is #{label}\n"
  l2 = find('#' + label)
  href =  l2[:href]
  case
    when type.match("from Articles")
      cmd =  "wget -O -  '#{href}' 2>/dev/null"
      page2 = `#{cmd}`
      pagedom = Nokogiri::HTML(page2)   
      #print "pagedom: #{pagedom}"
      pagedom.css("##{divtag}")[0].should_not be_nil 
      numx = pagedom.css("##{divtag}")[0].text 
      #print "total2 on view all page is #{numx}\n"
      #page.find(".#{divtag}").should_not be_nil
      #numx = page.find(".#{divtag}").text
      numx.should_not be_nil
      numx.match(/returned\s+(\d+)/).should_not be_nil
      numx.match(/returned\s+(\d+)/)[1].should_not be_nil
      num2 = numx.match(/returned\s+(\d+)/)[1]
    when type.match("from Catalog")
      click_link("#{label}")
      #cmd =  "wget -O -  '#{href}' 2>/dev/null"
      #print "****cmd is #{cmd}"
      #page2 = `#{cmd}`
      #page2 = page 
      #print "++++ #{page2}"
      #pagedom = Nokogiri::HTML(page2)   
      #pagedom.css('.'+divtag)[0].should_not be_nil 
      #numx = pagedom.css('.'+divtag)[0].text 
      page.find(".#{divtag}").should_not be_nil 
      numx = page.find(".#{divtag}").text
      #print "total2 on view (line #{__LINE__}  all page is '#{numx}'\n"
      numx.should_not be_nil
      if numx.match(/of\s+(\d+)/)
        numx.match(/of\s+(\d+)/).should_not be_nil
        numx.match(/of\s+(\d+)/)[1].should_not be_nil
        #print "Inspect:" +  numx.match(/of\s+([0-9,]) /).inspect
        num2 = numx.match(/of\s+([0-9,]+)/)[1]
      else
        numx.match(/(\d+)\s+result/).should_not be_nil
        numx.match(/(\d+)\s+result/)[1].should_not be_nil
        #print "Inspect:" +  numx.match(/(\d+)\s+result/).inspect
        num2 = numx.match(/([0-9,]+)\s+result/)[1]
      end
      #print "num2 on view (line #{__LINE__} all page is #{num2}\n"
    else
      visit(href)
      sleep 3
      #print "HREF is #{href}\n"
      total2 = find('.'+divtag,match: :first)
      total2.should_not be_nil
      #print "total2 on view all page is #{total2.text}\n"
      num2 = total2.text.match(/of ([0-9,]+) /)[1]
    end
    num.should_not be_nil
    num2.should_not be_nil
    num2.gsub!(',','')
    num.gsub!(',','')
    #print "box total of items = #{num}, and page number of items = #{num2}\n"
    diff = (num2.to_i - num.to_i).abs
    diff.should <=(20)
end

