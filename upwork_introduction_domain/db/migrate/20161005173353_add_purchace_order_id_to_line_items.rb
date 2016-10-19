class AddPurchaceOrderIdToLineItems < ActiveRecord::Migration[5.0]
  def change
    add_column :line_items, :purchace_order_id, :integer
  end
end
