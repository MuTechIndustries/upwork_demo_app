class AddSkuIdToLineItems < ActiveRecord::Migration[5.0]
  def change
    add_column :line_items, :sku_id, :integer
  end
end
