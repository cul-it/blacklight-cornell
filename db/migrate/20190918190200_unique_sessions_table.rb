class UniqueSessionsTable < ActiveRecord::Migration[5.2]
  def up
    remove_index :sessions, :session_id
    add_index :sessions, :session_id, :unique => true
  end

  def down
    remove_index :sessions, :session_id
    add_index :sessions, :session_id
  end
end
