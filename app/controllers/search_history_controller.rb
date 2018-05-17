# frozen_string_literal: true
class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory

  def set_return_path
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
    op = request.original_fullpath
    # if we headed for the login page, should remember PREVIOUS return to.
    if op.include?('logins') && !session[:cuwebauth_return_path].blank?   
      op = session[:cuwebauth_return_path]  
    end
    op.sub!('/range_limit','')
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  original = #{op.inspect}")
    refp = request.referer
    refp.sub!('/range_limit','') unless refp.nil?
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  referer path = #{refp}")
    session[:cuwebauth_return_path] =
      if (params['id'].present? && params['id'].include?('|'))
        '/bookmarks'
      elsif (params['id'].present? && op.include?('email'))
        "/catalog/afemail/#{params[:id]}"
      elsif (params['id'].present? && op.include?('unapi'))
         refp
      else
        op
      end
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  return path = #{session[:cuwebauth_return_path]}")
    return true
  end



  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  if   ENV['SAML_IDP_TARGET_URL']
      prepend_before_filter :set_return_path
  end

end
