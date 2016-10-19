class Sku < ApplicationRecord
	has_many :line_items

	before_save :ensure_sku

	def inventory
		received_line_items = LineItem.joins(:purchace_order).where("purchace_orders.has_been_received = ?", true).where(sku_id: id)
		received_line_items.sum("quantity")
	end

	def into_line_item
		LineItem::new(sku_id: id, name: name, sku_cache: sku)
	end

	def ensure_sku
		self.sku = name.parameterize unless sku.present?
	end

	class << self
		def free( free_sku )
			free_sku.destroy
			free_sku = "1/0" # infinity
		end
	end
end
