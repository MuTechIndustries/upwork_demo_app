class AddSkuValueToLineItems < ActiveRecord::Migration[5.0]
  def change
    add_column :line_items, :sku_cache, :string
    remove_column :line_items, :sku
  end
end
