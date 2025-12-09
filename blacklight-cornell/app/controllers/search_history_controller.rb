# frozen_string_literal: true
class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory

  def set_return_path
    op = request.original_fullpath
    # if we headed for the login page, should remember PREVIOUS return to.
    if op.include?('logins') && !session[:cuwebauth_return_path].blank?
      op = session[:cuwebauth_return_path]
    end
    op.sub!('/range_limit','')
    refp = request.referer
    refp.sub!('/range_limit','') unless refp.nil?

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

    return true
  end



  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  if   ENV['SAML_IDP_TARGET_URL']
      prepend_before_action :set_return_path
  end

end
