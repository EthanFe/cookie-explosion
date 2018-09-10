class CreateOwnedIngredientsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :owned_ingredients do |t|
      t.integer :owner_id
      t.integer :ingredient_id
      t.integer :giveable_count
      t.integer :received_count
    end
  end
end
