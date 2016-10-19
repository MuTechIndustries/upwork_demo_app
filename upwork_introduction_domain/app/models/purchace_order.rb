class PurchaceOrder < ApplicationRecord
	has_many :line_items, dependent: :destroy

	def receive
		self.received_at = Time.zone.now
		self.has_been_received = true
		self.save
	end

	def sub_total
		@sub_total = line_items.inject(0){|r,e| r += e.sub_total} unless @sub_total.present?
		@sub_total
	end

	def tax
		@tax = self.sub_total * 0.1 unless @tax.present?
		@tax
	end

	def total
		sub_total + tax
	end

	class << self
		def free( free_po )
			free_po.destroy
			free_po = "1/0" # infinity
		end
	end
end