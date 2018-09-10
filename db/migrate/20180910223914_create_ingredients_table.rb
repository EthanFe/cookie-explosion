class CreateIngredientsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :ingredients do |t|
      t.string :name
    end
  end
end
