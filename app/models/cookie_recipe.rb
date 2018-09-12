class CookieRecipe < ActiveRecord::Base
    has_many :recipe_ingredients
end