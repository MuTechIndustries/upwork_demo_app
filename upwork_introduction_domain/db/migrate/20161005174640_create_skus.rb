class CreateSkus < ActiveRecord::Migration[5.0]
  def change
    create_table :skus do |t|

      t.timestamps
    end
  end
end
