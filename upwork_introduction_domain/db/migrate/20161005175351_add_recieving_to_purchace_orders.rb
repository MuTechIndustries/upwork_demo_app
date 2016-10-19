class AddRecievingToPurchaceOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :purchace_orders, :has_been_received, :boolean
    add_column :purchace_orders, :received_at, :timestamp
  end
end
