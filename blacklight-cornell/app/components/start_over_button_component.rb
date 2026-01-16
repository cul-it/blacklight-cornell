# frozen_string_literal: true

class StartOverButtonComponent < Blacklight::StartOverButtonComponent
  def call
    link_to t('blacklight.search.start_over'), start_over_path, id: 'startOverLink', class: 'btn'
  end
end
