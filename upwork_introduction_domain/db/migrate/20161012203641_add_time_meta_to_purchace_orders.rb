class AddTimeMetaToPurchaceOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :purchace_orders, :placed_at, :timestamp
    add_column :purchace_orders, :expected_to_arive_at, :timestamp
  end
end
