class Owner < ActiveRecord::Base

    # .find
    # .find_by
    # .where
    # .all
    # .update
    has_many :owned_ingredients
    has_many :owned_cookies

    #receive_giveable_ingredient
    def receive_giveable_ingredient(ingredient)
        owned_ingredient = self.owned_ingredients.find_or_create_by(ingredient_id: ingredient.id)

        if owned_ingredient.received_count == nil && owned_ingredient.giveable_count == nil#if just created
            owned_ingredient.update(received_count: 0, giveable_count: 0)
        end

        owned_ingredient.update(giveable_count: owned_ingredient.giveable_count + 1)

    end

    #give_ingredient_to(receiver)
    def give_ingredient_to(receiver, ingredient)
        #check if owner has ingredient
        owned_ingredient = self.owned_ingredients.find_by(ingredient_id: ingredient.id)

        if owned_ingredient != nil && owned_ingredient.giveable_count > 0
            #decrement giveable ingredient count
            owned_ingredient.update(giveable_count: owned_ingredient.giveable_count - 1)
            
            #call receive_ingredient_from(self)
            receiver.receive_ingredient_from(self, ingredient)
        end

        #call receive_ingredient_from(self)
        receiver.receive_ingredient_from(self, ingredient)

    end

    #receive_ingredient_from(giver)
    def receive_ingredient_from(giver, ingredient)
        owned_ingredient = self.owned_ingredients.find_or_create_by(ingredient_id: ingredient.id)

        if owned_ingredient.received_count == nil #if just created
            owned_ingredient.update(received_count: 0, giveable_count: 0)
        end

        owned_ingredient.update(received_count: owned_ingredient.received_count + 1)
    end

    #list_cookie_recipes_you_can_bake
    def list_cookie_recipes_you_can_bake
        CookieRecipe.all.select do |cookie_recipe|
            self.can_bake?(cookie_recipe)
        end
        #returns type of cookie that can be baked
        #else returns none
    end
        
    #list_what_you_need_to_bake(cookie_type) and return hash of ingredient.id => count
    def list_what_you_need_to_bake(cookie_type)
        #get recipe ingredients for cookie_type
        ingredient_count_hash = {}
        cookie_type.recipe_ingredients.each do |recipe_ingredient|
            ingredient_count_hash[recipe_ingredient.ingredient_id] = recipe_ingredient.count
        end

        ingredient_count_hash
    end
    
    #bake_cookies(cookie_type)
    def bake_cookies(cookie_type)
        #check can_bake?(cookie_type)
        if can_bake?(cookie_type)
            #for each recipe ingredients of cookie_type
            cookie_type.recipe_ingredients.each do |recipe_ingredient|
                decrement_count = recipe_ingredient.count
                #find owned_ingredient
                self_owned_ingredient = self.owned_ingredients.find_by(ingredient_id: recipe_ingredient.ingredient_id)
                #decrement received ingredient count from self
                self_owned_ingredient.update(received_count: self_owned_ingredient.received_count - decrement_count)
            end

            #receive giveable cookie
            receive_giveable_cookie(cookie_type)

        end
    end

    #receive giveable cookie
    def receive_giveable_cookie(cookie_type)
        owned_cookie = self.owned_cookies.find_or_create_by(cookie_recipe_id: cookie_type.id)
        if owned_cookie.received_count == nil && owned_cookie.giveable_count == nil#if just created
            owned_cookie.update(received_count: 0, giveable_count: 0)
        end

        owned_cookie.update(giveable_count: owned_cookie.giveable_count + 1)
    end

    #can_bake?(cookie_type)
    def can_bake?(cookie_type)
        #get array of recipe ingredients that self has adequate count of
        has_enough_ingredients = true
        cookie_type.recipe_ingredients.each do |cookie_type_RI|
            owned_ingredients = self.owned_ingredients.find_by(ingredient_id: cookie_type_RI.ingredient_id)
            if !(owned_ingredients && owned_ingredients.received_count >= cookie_type_RI.count)
                has_enough_ingredients = false
            end
        end

        #return true or false
        has_enough_ingredients
    end
    
    #list all giveable ingredients owner has and return hash of ingredient.id => count
    def list_all_giveable_ingredients
        ingredient_count_hash = {}
        self.owned_ingredients.each do |owned_ingredient|
            ingredient_count_hash[owned_ingredient.ingredient_id] = owned_ingredient.giveable_count
        end
        ingredient_count_hash
    end

    #list all received ingredients owner has and return hash of ingredient_id => count
    def list_all_received_ingredients
        ingredient_count_hash = {}
        self.owned_ingredients.each do |owned_ingredient|
            ingredient_count_hash[owned_ingredient.ingredient_id] = owned_ingredient.received_count
        end
        ingredient_count_hash
    end

end