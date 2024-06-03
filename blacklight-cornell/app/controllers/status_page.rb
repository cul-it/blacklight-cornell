class StatusController < ApplicationController
  def index
    render html: StatusPage.check.html
  end
end
