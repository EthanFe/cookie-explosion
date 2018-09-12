class CookieRecipe < ActiveRecord::Base
    has_many :recipe_ingredients
    has_many :ingredients, through: :recipe_ingredients

    def list_what_you_need_to_bake
        #get recipe ingredients for self
        ingredient_count_hash = {}
        self.recipe_ingredients.each do |recipe_ingredient|
            ingredient_count_hash[recipe_ingredient.ingredient_id] = recipe_ingredient.count
        end

        ingredient_count_hash
    end
end