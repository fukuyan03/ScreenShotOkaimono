class AddUniqueIndexToShops < ActiveRecord::Migration[8.0]
  def change
    add_index :shops, [:user_id, :name], unique: true
  end
end
