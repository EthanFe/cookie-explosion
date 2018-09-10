class CreateRecipeingredientsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :recipe_ingredients do |t|
      t.integer :cookie_recipe_id
      t.integer :ingredient_id
      t.integer :count
    end
  end
end
