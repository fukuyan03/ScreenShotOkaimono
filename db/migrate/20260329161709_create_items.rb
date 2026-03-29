class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name
      t.string :brand
      t.integer :price
      t.text :summary
      t.string :source_platform
      t.string :source_author_name
      t.references :shop, null: false, foreign_key: true

      t.timestamps
    end
  end
end
