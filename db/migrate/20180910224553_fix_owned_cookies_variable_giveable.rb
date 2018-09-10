class FixOwnedCookiesVariableGiveable < ActiveRecord::Migration[5.2]
  def change
    rename_column :owned_cookies, :givable_count, :giveable_count
  end
end
