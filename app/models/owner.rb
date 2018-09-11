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
        owned_ingredient = OwnedIngredient.find_or_create_by(owner_id: self.id, ingredient_id: ingredient.id)

        if owned_ingredient.received_count == nil && owned_ingredient.giveable_count == nil#if just created
            owned_ingredient.update(received_count: 0, giveable_count: 0)
        end

        owned_ingredient.update(giveable_count: owned_ingredient.giveable_count + 1)

    end

    #give_ingredient_to(receiver)
    def give_ingredient_to(receiver, ingredient)
        #check if owner has ingredient
        owned_ingredient = OwnedIngredient.find_by(owner_id: self.id, ingredient_id: ingredient.id)

        if owned_ingredient != nil && owned_ingredient.giveable_count > 0
            #decrement count
            owned_ingredient.update(giveable_count: owned_ingredient.giveable_count - 1)
            
            #call receive_ingredient_from(self)
            receiver.receive_ingredient_from(self, ingredient)
        end

        #call receive_ingredient_from(self)
        receiver.receive_ingredient_from(self, ingredient)

    end

    #receive_ingredient_from(giver)
    def receive_ingredient_from(giver, ingredient)
        owned_ingredient = OwnedIngredient.find_or_create_by(owner_id: self.id, ingredient_id: ingredient.id)

        if owned_ingredient.received_count == nil #if just created
            owned_ingredient.update(received_count: 0, giveable_count: 0)
        end

        owned_ingredient.update(received_count: owned_ingredient.received_count + 1)
    end

    #list_bakeable_recipe
         #show if 1 cookie can be made 
         #returns type of cookie that can be baked (chocolate, sugar)
         #else returns none
        
    #list_what_you_need_to_bake(cookie_type)

    #bake_cookies(cookie_type)
        #check can_you_bake(cookie_type)
        #reduce ingredient count
        #receive cookie

    #can_you_bake(cookie_type)
        

    


end