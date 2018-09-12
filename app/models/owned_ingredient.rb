class OwnedIngredient < ActiveRecord::Base
    belongs_to :ingredient
    belongs_to :owner
end