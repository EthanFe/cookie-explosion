class CreateOwnerTable < ActiveRecord::Migration[5.0]
  def change
    create_table :owners do |t|
      t.string :name
    end
  end
end
