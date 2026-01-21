class SelectAllComponent < Blacklight::Component
  def initialize(blacklight_config:, response:)
    @blacklight_config = blacklight_config
    @response = response
  end

  def current_per_page
    (@response.rows if @response && @response.rows > 0) ||
      params.fetch(:per_page, @blacklight_config.default_per_page).to_i
  end

  def can_add_books
    helpers.current_or_guest_user.try(:bookmarks).blank? || 
      helpers.current_or_guest_user.bookmarks.count + current_per_page < BookBagsController::MAX_BOOKBAGS_COUNT
  end
end
