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

    @availability = []
    @documents.each do |doc|
      doc_availability = []
      if doc['availability_json'].present?
        availability = JSON.parse(doc['availability_json'])
        #availability: {"available"=>true, "availAt"=>{"ILR Multi-Copy Storage"=>"QA276.12 .M648 2013"}, "unavailAt"=>{"ILR Library (Ives Hall)"=>"QA276.12 .M648 2013"}}
        if availability['availAt'].present?
          availability['availAt'].each do |key, val|
            avail = {'location' => key,
              'callnumber' => val,
              'status' => 'available'}
            doc_availability << avail
          end
        end
        if availability['unavailAt'].present?
          availability['unavailAt'].each do |key, val|
            avail = {'location' => key,
              'callnumber' => val,
              'status' => 'not available'}
            doc_availability << avail
          end
        end
      else
        Rails.logger.debug "jgr25_log #{__FILE__} #{__LINE__}: No availability: "
      end
      @availability << doc_availability
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
