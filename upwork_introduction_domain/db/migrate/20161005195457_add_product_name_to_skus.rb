class AddProductNameToSkus < ActiveRecord::Migration[5.0]
  def change
    add_column :skus, :name, :string
  end
end
