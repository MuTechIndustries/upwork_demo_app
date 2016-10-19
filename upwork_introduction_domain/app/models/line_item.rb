class LineItem < ApplicationRecord
	belongs_to :purchace_order
	belongs_to :sku

	before_save :get_meta_if_not_present

	def get_meta_if_not_present
		unless sku_cache.present?
			sku = Sku::find(sku_id)
			self.name = sku.name
			self.sku_cache = sku.sku
		end
	end

	def sub_total
		quantity * price_per_unit
	end
end