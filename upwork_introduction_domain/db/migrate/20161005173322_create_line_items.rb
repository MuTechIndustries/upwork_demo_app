class CreateLineItems < ActiveRecord::Migration[5.0]
  def change
    create_table :line_items do |t|
      t.string :name
      t.string :sku
      t.string :quantity
      t.string :price_per_unit

      t.timestamps
    end
  end
end
