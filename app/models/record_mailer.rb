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
    @status         = details[:status]

    saveLevel = Rails.logger.level
    Rails.logger.level = 0
    Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: email_record"
    Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: Details: " + details.inspect
    Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: Params: " + params.inspect
    #Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: documents: " + @documents.inspect
    #puts caller(0..10)
    Rails.logger.level = saveLevel

    @documents do |doc|
      if doc['availability_json'].present?
        availability = JSON.parse(item.custom_data['availability_json'])
        Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: availability: " + availability
      end
    end

    if @callnumber.nil?
      @callnumber = params["callnumber"]
    end
    if @status.nil?
      @status = params["status"]
    end
    if details[:location].nil?
      details[:location] = params["location"]
    end
    if details[:templocation].nil?
      details[:templocation] = params["templocation"]
    end

    @callNumFirst = @callnumber.present? ? @callnumber.split('|| ') : nil
    @callnumber = []
    if @callNumFirst != nil
      @callNumFirst.each do |calls|
        @second = calls.split('| ')
        @callnumber << @second
      end
    end

    @statusFirst = @status.split('|| ')
    @status = []
    @statusFirst.each do |stats|
     @second = stats.split('| ')
     @status << @second
    end
    @location       = details[:location]
    @locationFirst = @location.split('|| ')
    @location = []
    @locationFirst.each do |locs|
      @second = locs.split('| ')
      @location << @second
    end
    @templocation = details[:templocation]
    @tempLocationFirst = @templocation.split('|| ')
    @templocation = []
    @tempLocationFirst.each do |locs|
      @second = locs.split('| ')
      @templocation << @second
    end
    @tiny           = details[:tiny]
    @url_gen_params = url_gen_params

    mail(:to => details[:to],  :subject => subject)
  end

  def sms_record(documents, details, url_gen_params)
    if sms_mapping[details[:carrier]]
      to = "#{details[:to]}@#{sms_mapping[details[:carrier]]}"
    else
      to = details[:to]
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
