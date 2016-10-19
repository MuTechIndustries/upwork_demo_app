namespace :seed do

	desc "Create demo data for POs Line Items and Skus"
	task inventory: :environment do

		puts "Cleaning old data..."
		[PurchaceOrder, LineItem, Sku].each do |model_class|
			model_class.send(:destroy_all)
		end
		DatabaseCleaner.clean_with(:truncation)
		puts "Completed"

		puts "Beginning database seed..."
		# create 5 skus
		puts "Creating 5 Skus"
		14.times do
			Sku::create( name: Faker::Commerce.product_name )
		end

		puts "Creating 4 purchace orders with line items"
		# create 4 POs
		def randome_date(leash, direction)
			choke = rand(leash)
			# direction = rand(2) & 1 == 1 # bool gen
			now = Time.zone.now
			direction == "future" ? now + choke.days : now - choke.days
		end
		7.times do
			po = PurchaceOrder::create(
					supply_company_name: Faker::Company.name,
					supply_company_street_address: Faker::Address.street_address,
					supply_company_city: Faker::Address::city,
					supply_company_state: Faker::Address.state,
					supply_company_zip: Faker::Address.zip,
					supply_company_email: Faker::Internet.email,
					supply_company_phone: Faker::PhoneNumber.cell_phone,
					placed_at: randome_date(15, "past"),
					expected_to_arive_at: randome_date(15, "future")
				)

			number_of_line_items = rand(7) + 5

			Sku::order("random()").limit(number_of_line_items).each do |sku|
				line_item = sku.into_line_item
				line_item.purchace_order_id = po.id
				line_item.quantity = rand(20) + 20
				line_item.price_per_unit = Faker::Commerce.price
				line_item.save
			end
		end
		PurchaceOrder::limit(3).each do |po|
			po.receive
		end
		puts "Completed"

	end

end
