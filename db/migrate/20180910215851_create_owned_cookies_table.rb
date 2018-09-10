class CreateOwnedCookiesTable < ActiveRecord::Migration[5.0]
  def change
    create_table :owned_cookies do |t|
      t.integer :user_id
      t.integer :cookie_recipe_id
      t.integer :givable_count
      t.integer :received_count
    end
  end
end
