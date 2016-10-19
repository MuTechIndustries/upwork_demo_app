# Javascript Core Prototype extensions
Array.prototype.randomElementIndex = ->
	Math.floor(Math.random() * this.length)

window.muObjectMerge = (target, source) ->
	_.each _.keys(source), (key) ->
		target[key] = source[key]

# Third party library global configurations
Chart.defaults.global.defaultFontColor = "#fff";

# Initialize top level app object and Draco.restClient
window.UpworkIntroApp = {}
UpworkIntroApp.restClient = DracoClient.restClientFactory("http://localhost:3000")

# Utility Functions
# Convert Rails time stamp to fullCalendar friendly timestamp
dracoDateToCalendarDate = (draco_date) ->
	draco_date.split("T")[0]

# Create events array from collection of purchace orders
calendarEventsFromPOCollection = (po_collection) ->
	calendar_events = []
	_.each po_collection.models, (event_data) ->
		order_placed_calendar_event = {}
		order_expected_arival_calendar_event = {}
		mutal_attrs = {}

		mutal_attrs.title = event_data.get('supply_company_name')
		mutal_attrs.url = "#purchace_orders/#{event_data.get('id')}"
		muObjectMerge(order_placed_calendar_event, mutal_attrs)
		muObjectMerge(order_expected_arival_calendar_event, mutal_attrs)

		order_placed_calendar_event.start = dracoDateToCalendarDate(event_data.get('placed_at')) if event_data.get('placed_at')
		order_placed_calendar_event.color = "#666034"
		order_expected_arival_calendar_event.start = dracoDateToCalendarDate(event_data.get('expected_to_arive_at')) if event_data.get('expected_to_arive_at')
		order_expected_arival_calendar_event.color = "#663834"

		calendar_events.push order_placed_calendar_event if order_placed_calendar_event.start
		calendar_events.push order_expected_arival_calendar_event if order_expected_arival_calendar_event.start
	calendar_events

$ ->
	UpworkIntroApp.view_attrs =
		skus_index:
			initialize: ->
				self = @
				@collection = UpworkIntroApp.restClient.restProtocols.where 'skus', {}, (data) ->
					self.data_checksum = md5(JSON.stringify(data))
				@render()
				@listenTo @collection, "update", @render
				setInterval ->
					self.collection = UpworkIntroApp.restClient.restProtocols.where 'skus', {}, (data) ->
						new_data_checksum = md5(JSON.stringify(data))
						if new_data_checksum != self.data_checksum
							self.render()
							self.data_checksum = new_data_checksum
				, 1000
			el: $("#main_content")
			template: _.template $("#skus_index_template").html()
			render: ->
				@$el.html @template
					skus: @collection.toJSON()
				ctx = $("#stock_chart")
				color_scheme = new ColorScheme
				background_colors = color_scheme.from_hue(21).scheme('triade').variation('soft').colors()
				border_colors = color_scheme.from_hue(21).scheme('triade').colors()
				data_background_colors = []
				data_border_colors = []
				_.each @collection, (elm) ->
					randomIndex = background_colors.randomElementIndex()
					data_background_colors.push "##{background_colors[randomIndex]}"
					data_border_colors.push "##{border_colors[randomIndex]}"
				@stock_chart = new Chart ctx,
					type: 'bar'
					data:
						labels: @collection.pluck("name")
						datasets: [
							{
								label: "# of units"
								data: @collection.pluck("inventory")
								backgroundColor: data_background_colors
								borderColor: data_border_colors
								borderWidth: 1
							}
						]
					options:
						scales:
							yAxes: [
								{
									ticks:
										beginAtZero: true
								}
							]

		purchace_orders_index:
			initialize: ->
				@collection = UpworkIntroApp.restClient.restProtocols.where('purchace_orders')
				@render()
				@listenTo @collection, "update", @render
			el: $("#main_content")
			template: _.template $("#purchace_orders_index_template").html()
			render: ->
				@$el.html @template
					purchace_orders: @collection.toJSON()
				events = calendarEventsFromPOCollection @collection
				$("#purchace_order_calendar").fullCalendar
					events: events
				$("#purchace_order_list").fullCalendar
					events: events
					defaultView: 'listMonth'

		purchace_order_show:
			initialize: (id) ->
				@model = UpworkIntroApp.restClient.restProtocols.find('purchace_orders', id)
				@render()
				@listenTo @model, "change", @render
			el: $("#main_content")
			template: _.template $("#purchace_order_show_template").html()
			events:
				"click #delete_po" : "free_po"
				"click #receive_po" : "receive_po"
				"click #unreceive_po" : "unreceive_po"
			free_po: ->
				@model.free ->
					UpworkIntroApp.router.navigate "#purchace_orders",
						trigger: true
			receive_po: ->
				@model.set('has_been_received', true)
				@model.save()
			unreceive_po: ->
				@model.set('has_been_received', false)
				@model.save()
			render: ->
				@$el.html @template
					po: @model

		purchace_order_edit:
			initialize: (id) ->
				@model = if id
					UpworkIntroApp.restClient.restProtocols.find('purchace_orders', id)
				else
					UpworkIntroApp.restClient.restProtocols.new('purchace_orders')
				@render()
				@listenTo @model, "change", @render
			el: $("#main_content")
			template: _.template $("#purchace_order_edit_template").html()
			events:
				"click #save_button" : "save"
				"click .remove_line_item" : "remove_line_item"
				"click #add_new_line_item" : "add_new_line_item"
			save: ->
				self = @
				new_attributes = {}
				$("#supply_company_information input").each ->
					$elm = $(this)
					column_name = $elm.attr('id').replace("_field", "")
					new_attributes[column_name] = $elm.val()

				$("#shipping_meta_data input").each ->
					$elm = $(this)
					column_name = $elm.attr('id').replace("_field", "")
					new_attributes[column_name] = $elm.val()

				@model.set(new_attributes)

				$(".line_item_edit").each ->
					$line_item = $(this)
					id = parseInt($line_item.find("input[name='id']").val())
					line_item = _.find self.model.get('line_items'), (line_item) ->
						line_item.id == id
					$line_item.find(".form-group input").each ->
						$elm = $(this)
						column_name = $elm.attr('name')
						value = $elm.val()
						line_item[column_name] = value

				@model.save ->
					UpworkIntroApp.router.navigate "#purchace_orders",
						trigger: true
			add_new_line_item: ->
				current_id = @model.get('id')
				sku_id = $("#new_line_item_sku_id").val()
				price_per_unit = $("#new_line_item_price_per_unit").val()
				quantity = $("#new_line_item_quantity").val()
				line_items = @model.get('line_items')
				line_items.push
					sku_id: sku_id
					quantity: quantity
					price_per_unit: price_per_unit
				@model.save ->
					UpworkIntroApp.router.navigate "#purchace_orders/#{current_id}",
						trigger: true
			remove_line_item: (ev) ->
				id_to_free = $(ev.currentTarget).data('line-item-id')
				new_line_items = _.filter @model.get('line_items'), (line_item) ->
					line_item.id != id_to_free
				@model.set('line_items', new_line_items)
			render: ->
				@$el.html @template
					po: @model
				@$el.find("input.date_picker").datepicker()
				self = @
				$.ajax
					url: "#{UpworkIntroApp.restClient.apiRoot}/skus"
					success: (data) ->
						$("#new_line_item_sku_id").select2
							placeholder: "Select A Sku"
							data: _.map data, (line_item) ->
								{id: line_item.id, text: line_item.name}

	UpworkIntroApp.set_main_content_view = (view_name, router_params) ->
		delete UpworkIntroApp.main_view if UpworkIntroApp.main_view
		MainContentView = Backbone.View.extend UpworkIntroApp.view_attrs[view_name]
		UpworkIntroApp.main_view = new MainContentView(router_params)

	UpworkIntroApp.Router = Backbone.Router.extend
		routes:
			"" : "skus_index"
			"skus" : "skus_index"
			"purchace_orders" : "purchace_orders_index"
			"purchace_orders/new" : "new_purchace_order"
			"purchace_orders/:id" : "show_purchace_order"
			"purchace_orders/:id/edit" : "edit_purchace_order"
		skus_index: ->
			UpworkIntroApp.set_main_content_view("skus_index")
		purchace_orders_index: ->
			UpworkIntroApp.set_main_content_view("purchace_orders_index")
		show_purchace_order: (id) ->
			UpworkIntroApp.set_main_content_view("purchace_order_show", id)
		edit_purchace_order: (id) ->
			UpworkIntroApp.set_main_content_view("purchace_order_edit", id)
		new_purchace_order: ->
			UpworkIntroApp.set_main_content_view("purchace_order_edit")
	# Start THR33PL Application
	UpworkIntroApp.router = new UpworkIntroApp.Router
	Backbone.history.start()