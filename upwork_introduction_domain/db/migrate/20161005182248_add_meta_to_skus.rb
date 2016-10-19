class AddMetaToSkus < ActiveRecord::Migration[5.0]
  def change
    add_column :skus, :sku, :string
  end
end
