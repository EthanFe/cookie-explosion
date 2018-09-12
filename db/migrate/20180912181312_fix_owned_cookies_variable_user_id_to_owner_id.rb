class FixOwnedCookiesVariableUserIdToOwnerId < ActiveRecord::Migration[5.2]
  def change
    rename_column :owned_cookies, :user_id, :owner_id
  end
end
