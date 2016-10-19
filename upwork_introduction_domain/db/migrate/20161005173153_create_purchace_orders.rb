class CreatePurchaceOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :purchace_orders do |t|
      t.string :supply_company_name
      t.string :supply_company_street_address
      t.string :supply_company_city
      t.string :supply_company_state
      t.string :supply_company_zip
      t.string :supply_company_email
      t.string :supply_company_phone

      t.timestamps
    end
  end
end
