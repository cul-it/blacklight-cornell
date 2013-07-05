# -*- encoding : utf-8 -*-
# This module provides the body of an email export based on the document's semantic values
module Blacklight::Solr::Document::Sms

  # Return a text string that will be the body of the email
  def to_sms_text
    semantics = self.to_semantic_values
    body = []
    body << I18n.t('blacklight.sms.text.title', :value => semantics[:title].first) unless semantics[:title].blank?
    body << I18n.t('blacklight.sms.text.callnumber', :value => semantics[:lc_callnum_display].join(" ")) unless semantics[:lc_callnum_display].blank?
    body << I18n.t('blacklight.sms.text.location', :value => semantics[:location].join(" ")) unless semantics[:location].blank?
    body << I18n.t('blacklight.sms.text.tiny', :value => semantics[:tiny].join(" ")) unless semantics[:tiny].blank?
    return body.join unless body.empty?
  end

end
