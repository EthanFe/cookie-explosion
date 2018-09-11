class AddEmojiColumnToCookies < ActiveRecord::Migration[5.2]
  def change
    add_column :cookie_recipes, :emoji, :string
  end
end
