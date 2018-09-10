class CreateRecipes < ActiveRecord::Migration[5.0]
  def change
    create_table :cookie_recipes do |t|
      t.string :name
    end
  end
end
