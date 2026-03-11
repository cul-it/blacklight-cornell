# -*- encoding : utf-8 -*-

# Only works for documents with a #to_marc right now.
class RecordMailer < ActionMailer::Base
  default :from => ENV["SMTP_FROM"]
  def email_record(documents, details, url_gen_params, params)
    #raise ArgumentError.new("RecordMailer#email_record only works with documents with a #to_marc") unless document.respond_to?(:to_marc)

    subject = I18n.t('blacklight.email.text.subject')

    @documents      = documents
    @message        = details[:message]
    @url_gen_params = url_gen_params

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
              'status' => 'Available'}
            doc_availability << avail
          end
        end
        if availability['unavailAt'].present?
          availability['unavailAt'].each do |key, val|
            avail = {'location' => key,
              'callnumber' => val,
              'status' => 'Not Available'}
            doc_availability << avail
          end
        end
      end
      @availability << doc_availability
    end

    delivery_options = {
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      address: ENV["SMTP_ADDRESS"]
    }

    mail(:to => details[:to],  :subject => subject,
      delivery_method_options: delivery_options)
  end
end
