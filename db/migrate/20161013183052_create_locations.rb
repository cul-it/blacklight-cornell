class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.integer :voyager_id
      t.string :code
      t.string :display_name
      t.string :hours_page
      t.boolean :rmc_aeon

      t.timestamps null: false
    end
    add_index :locations, :voyager_id, unique: true
    add_index :locations, :code, unique: true
  end
end
