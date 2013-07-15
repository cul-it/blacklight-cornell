class ChangeSessionDataToLongText < ActiveRecord::Migration
  def up
  	change_column :sessions, :data, :longtext
  end

  def down
  	change_column :sessions, :data, :text
  end
end
