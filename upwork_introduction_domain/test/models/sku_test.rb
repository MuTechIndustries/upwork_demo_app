require 'test_helper'

class SkuTest < ActiveSupport::TestCase
	
	# Instance methods
	test "inventory" do
		sku = Sku::create(sku: "AF1243S89")
		po = PurchaceOrder::create(has_been_received: false)
		line_item = LineItem::create(purchace_order_id: po.id, sku_id: sku.id, quantity: 100)
		assert_equal 0, sku.inventory, "Should not have inventory until PO is recieved"
		po.has_been_received = true
		po.save
		assert_equal 100, sku.inventory, "Should have inventory after PO is recieved"
	end

	test "into_line_item" do
		sku = Sku::create(sku: "AF1243S89", name: "Flux Capaciter")
		line_item = sku.into_line_item
		assert_equal LineItem, line_item.class, "into_line_item should return a line_item"
		assert_equal sku.id, line_item.sku_id, "should associate with sku"
		assert_equal sku.name, line_item.name, "should copy sku name"
	end

end
