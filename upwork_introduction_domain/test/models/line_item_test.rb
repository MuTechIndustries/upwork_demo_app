require 'test_helper'

class LineItemTest < ActiveSupport::TestCase
	test "sub_total" do
		line_item = LineItem::new(quantity: 5, price_per_unit: 100)
		assert_equal 500, line_item.sub_total, "Did not calculate the correct sub total"
	end
end
