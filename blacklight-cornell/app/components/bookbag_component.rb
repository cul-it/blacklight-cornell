# frozen_string_literal: true

# Render a bookbag widget to add / remove document from bookbag
class BookbagComponent < Blacklight::Document::BookmarkComponent
  # @param [Blacklight::Document] document
  # @param [Blacklight::Configuration::ToolConfig] action
  # @param [Boolean] checked
  # @param [Object] bookbag_path the rails route to use for bookbags
  def initialize(document:, action: nil, checked: nil, bookbag_path: nil, bookbag: nil,**kwargs)
    @document = document
    @checked = checked
    @bookbag_path = bookbag_path
    @bookbag = bookbag

    super(document: document, action: action, **kwargs)
  end

  delegate :current_or_guest_user, to: :helpers

  def bookbag_path
    @bookbag_path || helpers.add_pindex_path(@document)
  end

  # Check if the document is in the user's bookbag
  def bookbagged?
    return false unless @bookbag

    @bookbag.index.any? { |x| x == @document.id }
  end

  def can_add_books?
    !(current_or_guest_user.present? && current_or_guest_user.bookmarks.present? && current_or_guest_user.bookmarks.count.present?) || 
      (current_or_guest_user.bookmarks.count < BookBagsController::MAX_BOOKBAGS_COUNT)
  end
end