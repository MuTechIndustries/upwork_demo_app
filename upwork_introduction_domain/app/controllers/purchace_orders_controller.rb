class PurchaceOrdersController < ApplicationController
	before_action :decode_times

	def index
		@purchace_order_models = PurchaceOrder.includes(:line_items).all
		@purchace_order_hashes = @purchace_order_models.map do |po|
			element_hash = po.attributes
			element_hash[:line_items] = po.line_items.map{|e| e.attributes}
			element_hash
		end
		render json: @purchace_order_hashes
	end
	def show
		purchace_order = PurchaceOrder.includes(:line_items).find(params[:id])
		purchace_order_hash = purchace_order.attributes
		purchace_order_hash[:sub_total] = '%.2f' % purchace_order.sub_total
		purchace_order_hash[:tax] = '%.2f' % purchace_order.tax
		purchace_order_hash[:total] = '%.2f' % purchace_order.total
		purchace_order_hash[:line_items] = purchace_order.line_items.order(created_at: :asc).map{|e| e.attributes}
		encode_times(purchace_order_hash)
		render json: purchace_order_hash
	end
	def create
		purchace_order_hash = params[:payload]
		line_items_hash = line_items_from_po_hash(purchace_order_hash)
		purchace_order = PurchaceOrder::create(po_params(purchace_order_hash))
		line_items_hash.each do |line_item_hash|
			line_item = purchace_order.line_items.where(sku_id: line_item_hash[:sku_id]).first_or_initialize
			line_item.quantity = line_item_hash[:price_per_unit]
			line_item.quantity = line_item_hash[:quantity]
			line_item.save
		end
		render json: {status: "success", new_model_id: purchace_order.id}
	end	
	def update
		purchace_order = PurchaceOrder::find(params[:id])
		purchace_order_hash = params[:payload]
		line_items_hash = line_items_from_po_hash(purchace_order_hash)
		purchace_order.update_attributes(po_params(purchace_order_hash))
		line_items_to_keep = line_items_hash.map{|e| e[:id]}
		purchace_order.line_items.where.not(id: line_items_to_keep).destroy_all

		line_items_hash.each do |line_item_hash|
			line_item = purchace_order.line_items.where(sku_id: line_item_hash[:sku_id]).first_or_initialize
			line_item.price_per_unit = line_item_hash[:price_per_unit]
			line_item.quantity = line_item_hash[:quantity]
			line_item.save
		end
		render json: {status: "success"}
	end
	def free
		@free_po = PurchaceOrder::find(params[:id])
		PurchaceOrder::free( @free_po )
		@free_po = "1/0" #infinity
		render json: {status: "success"}
		# Go on your free now...
	end
	
	private
	def po_params(the_hash)
		the_hash.permit(:supply_company_name, :supply_company_street_address, :supply_company_city, :supply_company_state, :supply_company_zip, :supply_company_email, :supply_company_phone, :has_been_received, :received_at, :placed_at, :expected_to_arive_at)
	end

	def line_items_from_po_hash(po_hash)
		line_items = po_hash.delete(:line_items)
		line_items.present? ? line_items.values : []
	end

	def encode_times(the_hash)
		the_hash.keys.select{|e| the_hash[e].present? and e[-3..-1] ==  "_at"}.each do |time_key|
			the_hash[time_key] = the_hash[time_key].strftime("%m/%d/%Y")
		end
	end

	def decode_times
		if params[:payload].present?
			object_attrs = params[:payload]
			object_attrs.keys.select{|e| object_attrs[e].present? and e[-3..-1] ==  "_at"}.each do |time_key|
				month, day, year = object_attrs[time_key].split("/").map{|e| e.to_i}
				date_object = Date.new(year, month, day)
				object_attrs[time_key] = date_object
			end
		end
	end
end





