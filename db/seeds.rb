# INGREDIENTS

butter = Ingredient.create(name: "Butter", emoji: "butter")
sugar = Ingredient.create(name: "Sugar", emoji: "sugar")
egg = Ingredient.create(name: "Egg", emoji: "egg")
flour = Ingredient.create(name: "Flour", emoji: "flour")

chocolate = Ingredient.create(name: "Chocolate", emoji: "chocolate_bar")
peanut_butter = Ingredient.create(name: "Peanut Butter", emoji: "peanuts")


# RECIPES

chocochip_recipe = CookieRecipe.create(name: "Chocolate Chip", emoji: "cookie")
# add recipe ingredients to chocolate chip recipe
chocochip_recipe.recipe_ingredients.create(ingredient_id: butter.id, count: 1)
chocochip_recipe.recipe_ingredients.create(ingredient_id: sugar.id, count: 1)
chocochip_recipe.recipe_ingredients.create(ingredient_id: egg.id, count: 1)
chocochip_recipe.recipe_ingredients.create(ingredient_id: flour.id, count: 1)
chocochip_recipe.recipe_ingredients.create(ingredient_id: chocolate.id, count: 1)

peanut_butter_recipe = CookieRecipe.create(name: "Peanut Butter", emoji: "pbcookie")
# add recipe ingredients to peanut butter recipe
peanut_butter_recipe.recipe_ingredients.create(ingredient_id: butter.id, count: 1)
peanut_butter_recipe.recipe_ingredients.create(ingredient_id: sugar.id, count: 1)
peanut_butter_recipe.recipe_ingredients.create(ingredient_id: egg.id, count: 1)
peanut_butter_recipe.recipe_ingredients.create(ingredient_id: flour.id, count: 1)
peanut_butter_recipe.recipe_ingredients.create(ingredient_id: peanut_butter.id, count: 1)

sugar_cookie_recipe = CookieRecipe.create(name: "Sugar", emoji: "sugarcookie")
# add recipe ingredients to sugar cookie recipe
sugar_cookie_recipe.recipe_ingredients.create(ingredient_id: butter.id, count: 1)
sugar_cookie_recipe.recipe_ingredients.create(ingredient_id: sugar.id, count: 2)
sugar_cookie_recipe.recipe_ingredients.create(ingredient_id: egg.id, count: 1)
sugar_cookie_recipe.recipe_ingredients.create(ingredient_id: flour.id, count: 1)



