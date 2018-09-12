require_relative '../config/environment'

# ethan = Owner.create(name: "Ethan") #id: 1
# kim = Owner.create(name: "Kim") #id: 2

# butter = Ingredient.create(name: "Butter") #id: 1
# sugar = Ingredient.create(name: "Sugar") #id: 2

# chocolate_chip_recipe = CookieRecipe.create(name: "Chocolate Chip") #id: 1
# peanut_butter_recipe = CookieRecipe.create(name: "Peanut Butter") #id: 2

#give owner receivable ingredient
# Owner.first.receive_ingredient_from(Owner.last, Ingredient.first) #ethan id:1 receive_ingredient_from kim id:2 , butter id: 1
# Owner.first.receive_ingredient_from(Owner.last, Ingredient.last) #ethan id:1 receive_ingredient_from kim id:2 , sugar id: 2

#give all owners giveable ingredients
# Owner.all.each do |owner|
#     Ingredient.all.each do |ingredient|
#         owner.receive_giveable_ingredient(ingredient)
#     end
# end

#assign ingredients butter id: 1 and sugar id: 2 to cookie recipes chocolate_chip_recipe id: 1 & peanut_butter_recipe id: 2
# CookieRecipe.all.each do |cookie_recipe|
#     Ingredient.all.each do |ingredient|
#         RecipeIngredient.create(cookie_recipe_id: cookie_recipe.id, ingredient_id: ingredient.id, count: 1)
#     end
# end

# chocolate = Ingredient.create(name: "Chocolate") #id: 3
# RecipeIngredient.create(cookie_recipe_id: CookieRecipe.first.id, ingredient_id: Ingredient.third.id)
# OwnedIngredient.create(owner_id: 1, ingredient_id: Ingredient.third.id, giveable_count: 1, received_count: 2)
binding.pry

puts "HELLO WORLD"
