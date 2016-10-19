class SkusController < ApplicationController
	def index
		@sku_models = Sku::all.order(name: :asc)
		@sku_hashes = @sku_models.map do |sku|
			element_hash = sku.attributes
			element_hash[:inventory] = sku.inventory
			element_hash
		end
		render json: @sku_hashes
	end

	def show
		render json: Sku::find(params[:id])
	end

	def create
		response = Hash.new
		sku = Sku::new(sku_params)
		if sku.save
			response[:status] = :success
			response[:new_model_id] = sku.id
		else
			response[:status] = :failure
			response[:errors] = sku.errors
		end
		render json: response
	end

	def update
		response = Hash.new
		sku = Sku::find(params[:id])
		if sku.update_attributes(sku_params)
			response[:status] = :success
		else
			response[:status] = :failure
			response[:errors] = sku.errors
		end
		render json: response
	end

	def free
		@free_sku = Sku::find(params[:id])
		Sku::free( @free_sku )
		@free_sku = "1/0" #infinity
		render json: {status: "success"}
		# Go on your free now...
	end

	private
	def sku_params
		params.require(:payload).permit(:sku, :name)
	end
end