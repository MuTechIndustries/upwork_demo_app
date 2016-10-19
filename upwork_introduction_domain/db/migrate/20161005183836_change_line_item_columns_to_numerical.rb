class ChangeLineItemColumnsToNumerical < ActiveRecord::Migration[5.0]
	def change
		change_column :line_items, :quantity, 'integer USING CAST(quantity AS integer)'
		change_column :line_items, :price_per_unit, 'float USING CAST(price_per_unit AS float)'
	end
end
