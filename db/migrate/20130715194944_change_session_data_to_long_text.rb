class ChangeSessionDataToLongText < ActiveRecord::Migration[5.2]
  def up
  	change_column :sessions, :data, :longtext
  end

  def down
  	change_column :sessions, :data, :text
  end
end
