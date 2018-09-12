class RenameOwnerNameColumn < ActiveRecord::Migration[5.2]
  def change
    rename_column :owners, :name, :slack_id
  end
end
