class OwnedCookie < ActiveRecord::Base
    belongs_to :owner
end