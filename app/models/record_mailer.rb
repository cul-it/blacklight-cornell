# -*- encoding : utf-8 -*-
# Only works for documents with a #to_marc right now. 
class RecordMailer < ActionMailer::Base
  default :from => "culsearch@cornell.edu"
  def email_record(documents, details, url_gen_params, params)
    #raise ArgumentError.new("RecordMailer#email_record only works with documents with a #to_marc") unless document.respond_to?(:to_marc)
        
#    subject = I18n.t('blacklight.email.text.subject', :count => documents.length, :title => (documents.first.to_semantic_values[:title] rescue 'N/A') )
    subject = "Item(s) from the Cornell University Library Catalog"
    
    @documents      = documents
    @message        = details[:message]
    @callnumber     = details[:callnumber]
    @callNumFirst = @callnumber.split('|| ')
    @callnumber = []
    @callNumFirst.each do |calls|
      @second = calls.split('| ')
      @callnumber << @second
    end
    @location       = details[:location]
    @locationFirst = @location.split('|| ')
    @location = []
    @locationFirst.each do |locs|
      @second = locs.split('| ')
      @location << @second
    end
    @templocation = []
    @templocation = details[:templocation]
    @tiny           = details[:tiny]
    @url_gen_params = url_gen_params
    
    mail(:to => details[:to],  :subject => subject)
  end
  
  def sms_record(documents, details, url_gen_params)
    if sms_mapping[details[:carrier]]
      to = "#{details[:to]}@#{sms_mapping[details[:carrier]]}"
    end
    @documents      = documents
    @callnumber     = details[:callnumber]
    @location       = details[:location]
    @tiny           = details[:tiny]
    @url_gen_params = url_gen_params
    mail(:to => to, :subject => "")
  end

  protected
  
  def sms_mapping
    {'virgin' => 'vmobl.com',
    'att' => 'txt.att.net',
    'verizon' => 'vtext.com',
    'nextel' => 'messaging.nextel.com',
    'sprint' => 'messaging.sprintpcs.com',
    'tmobile' => 'tmomail.net',
    'alltel' => 'message.alltel.com',
    'cricket' => 'mms.mycricket.com'}
  end
end
