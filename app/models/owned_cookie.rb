class OwnedCookie < ActiveRecord::Base
    belongs_to :owner
    belongs_to :cookie_recipe
end