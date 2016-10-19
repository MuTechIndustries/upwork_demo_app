(function() {
  var calendarEventsFromPOCollection, dracoDateToCalendarDate;

  Array.prototype.randomElementIndex = function() {
    return Math.floor(Math.random() * this.length);
  };

  window.muObjectMerge = function(target, source) {
    return _.each(_.keys(source), function(key) {
      return target[key] = source[key];
    });
  };

  Chart.defaults.global.defaultFontColor = "#fff";

  window.UpworkIntroApp = {};

  UpworkIntroApp.restClient = DracoClient.restClientFactory("http://localhost:3000");

  dracoDateToCalendarDate = function(draco_date) {
    return draco_date.split("T")[0];
  };

  calendarEventsFromPOCollection = function(po_collection) {
    var calendar_events;
    calendar_events = [];
    _.each(po_collection.models, function(event_data) {
      var mutal_attrs, order_expected_arival_calendar_event, order_placed_calendar_event;
      order_placed_calendar_event = {};
      order_expected_arival_calendar_event = {};
      mutal_attrs = {};
      mutal_attrs.title = event_data.get('supply_company_name');
      mutal_attrs.url = "#purchace_orders/" + (event_data.get('id'));
      muObjectMerge(order_placed_calendar_event, mutal_attrs);
      muObjectMerge(order_expected_arival_calendar_event, mutal_attrs);
      if (event_data.get('placed_at')) {
        order_placed_calendar_event.start = dracoDateToCalendarDate(event_data.get('placed_at'));
      }
      order_placed_calendar_event.color = "#666034";
      if (event_data.get('expected_to_arive_at')) {
        order_expected_arival_calendar_event.start = dracoDateToCalendarDate(event_data.get('expected_to_arive_at'));
      }
      order_expected_arival_calendar_event.color = "#663834";
      if (order_placed_calendar_event.start) {
        calendar_events.push(order_placed_calendar_event);
      }
      if (order_expected_arival_calendar_event.start) {
        return calendar_events.push(order_expected_arival_calendar_event);
      }
    });
    return calendar_events;
  };

  $(function() {
    UpworkIntroApp.view_attrs = {
      skus_index: {
        initialize: function() {
          var self;
          self = this;
          this.collection = UpworkIntroApp.restClient.restProtocols.where('skus', {}, function(data) {
            return self.data_checksum = md5(JSON.stringify(data));
          });
          this.render();
          this.listenTo(this.collection, "update", this.render);
          return setInterval(function() {
            return self.collection = UpworkIntroApp.restClient.restProtocols.where('skus', {}, function(data) {
              var new_data_checksum;
              new_data_checksum = md5(JSON.stringify(data));
              if (new_data_checksum !== self.data_checksum) {
                self.render();
                return self.data_checksum = new_data_checksum;
              }
            });
          }, 1000);
        },
        el: $("#main_content"),
        template: _.template($("#skus_index_template").html()),
        render: function() {
          var background_colors, border_colors, color_scheme, ctx, data_background_colors, data_border_colors;
          this.$el.html(this.template({
            skus: this.collection.toJSON()
          }));
          ctx = $("#stock_chart");
          color_scheme = new ColorScheme;
          background_colors = color_scheme.from_hue(21).scheme('triade').variation('soft').colors();
          border_colors = color_scheme.from_hue(21).scheme('triade').colors();
          data_background_colors = [];
          data_border_colors = [];
          _.each(this.collection, function(elm) {
            var randomIndex;
            randomIndex = background_colors.randomElementIndex();
            data_background_colors.push("#" + background_colors[randomIndex]);
            return data_border_colors.push("#" + border_colors[randomIndex]);
          });
          return this.stock_chart = new Chart(ctx, {
            type: 'bar',
            data: {
              labels: this.collection.pluck("name"),
              datasets: [
                {
                  label: "# of units",
                  data: this.collection.pluck("inventory"),
                  backgroundColor: data_background_colors,
                  borderColor: data_border_colors,
                  borderWidth: 1
                }
              ]
            },
            options: {
              scales: {
                yAxes: [
                  {
                    ticks: {
                      beginAtZero: true
                    }
                  }
                ]
              }
            }
          });
        }
      },
      purchace_orders_index: {
        initialize: function() {
          this.collection = UpworkIntroApp.restClient.restProtocols.where('purchace_orders');
          this.render();
          return this.listenTo(this.collection, "update", this.render);
        },
        el: $("#main_content"),
        template: _.template($("#purchace_orders_index_template").html()),
        render: function() {
          var events;
          this.$el.html(this.template({
            purchace_orders: this.collection.toJSON()
          }));
          events = calendarEventsFromPOCollection(this.collection);
          $("#purchace_order_calendar").fullCalendar({
            events: events
          });
          return $("#purchace_order_list").fullCalendar({
            events: events,
            defaultView: 'listMonth'
          });
        }
      },
      purchace_order_show: {
        initialize: function(id) {
          this.model = UpworkIntroApp.restClient.restProtocols.find('purchace_orders', id);
          this.render();
          return this.listenTo(this.model, "change", this.render);
        },
        el: $("#main_content"),
        template: _.template($("#purchace_order_show_template").html()),
        events: {
          "click #delete_po": "free_po",
          "click #receive_po": "receive_po",
          "click #unreceive_po": "unreceive_po"
        },
        free_po: function() {
          return this.model.free(function() {
            return UpworkIntroApp.router.navigate("#purchace_orders", {
              trigger: true
            });
          });
        },
        receive_po: function() {
          this.model.set('has_been_received', true);
          return this.model.save();
        },
        unreceive_po: function() {
          this.model.set('has_been_received', false);
          return this.model.save();
        },
        render: function() {
          return this.$el.html(this.template({
            po: this.model
          }));
        }
      },
      purchace_order_edit: {
        initialize: function(id) {
          this.model = id ? UpworkIntroApp.restClient.restProtocols.find('purchace_orders', id) : UpworkIntroApp.restClient.restProtocols["new"]('purchace_orders');
          this.render();
          return this.listenTo(this.model, "change", this.render);
        },
        el: $("#main_content"),
        template: _.template($("#purchace_order_edit_template").html()),
        events: {
          "click #save_button": "save",
          "click .remove_line_item": "remove_line_item",
          "click #add_new_line_item": "add_new_line_item"
        },
        save: function() {
          var new_attributes, self;
          self = this;
          new_attributes = {};
          $("#supply_company_information input").each(function() {
            var $elm, column_name;
            $elm = $(this);
            column_name = $elm.attr('id').replace("_field", "");
            return new_attributes[column_name] = $elm.val();
          });
          $("#shipping_meta_data input").each(function() {
            var $elm, column_name;
            $elm = $(this);
            column_name = $elm.attr('id').replace("_field", "");
            return new_attributes[column_name] = $elm.val();
          });
          this.model.set(new_attributes);
          $(".line_item_edit").each(function() {
            var $line_item, id, line_item;
            $line_item = $(this);
            id = parseInt($line_item.find("input[name='id']").val());
            line_item = _.find(self.model.get('line_items'), function(line_item) {
              return line_item.id === id;
            });
            return $line_item.find(".form-group input").each(function() {
              var $elm, column_name, value;
              $elm = $(this);
              column_name = $elm.attr('name');
              value = $elm.val();
              return line_item[column_name] = value;
            });
          });
          return this.model.save(function() {
            return UpworkIntroApp.router.navigate("#purchace_orders", {
              trigger: true
            });
          });
        },
        add_new_line_item: function() {
          var current_id, line_items, price_per_unit, quantity, sku_id;
          current_id = this.model.get('id');
          sku_id = $("#new_line_item_sku_id").val();
          price_per_unit = $("#new_line_item_price_per_unit").val();
          quantity = $("#new_line_item_quantity").val();
          line_items = this.model.get('line_items');
          line_items.push({
            sku_id: sku_id,
            quantity: quantity,
            price_per_unit: price_per_unit
          });
          return this.model.save(function() {
            return UpworkIntroApp.router.navigate("#purchace_orders/" + current_id, {
              trigger: true
            });
          });
        },
        remove_line_item: function(ev) {
          var id_to_free, new_line_items;
          id_to_free = $(ev.currentTarget).data('line-item-id');
          new_line_items = _.filter(this.model.get('line_items'), function(line_item) {
            return line_item.id !== id_to_free;
          });
          return this.model.set('line_items', new_line_items);
        },
        render: function() {
          var self;
          this.$el.html(this.template({
            po: this.model
          }));
          this.$el.find("input.date_picker").datepicker();
          self = this;
          return $.ajax({
            url: UpworkIntroApp.restClient.apiRoot + "/skus",
            success: function(data) {
              return $("#new_line_item_sku_id").select2({
                placeholder: "Select A Sku",
                data: _.map(data, function(line_item) {
                  return {
                    id: line_item.id,
                    text: line_item.name
                  };
                })
              });
            }
          });
        }
      }
    };
    UpworkIntroApp.set_main_content_view = function(view_name, router_params) {
      var MainContentView;
      if (UpworkIntroApp.main_view) {
        delete UpworkIntroApp.main_view;
      }
      MainContentView = Backbone.View.extend(UpworkIntroApp.view_attrs[view_name]);
      return UpworkIntroApp.main_view = new MainContentView(router_params);
    };
    UpworkIntroApp.Router = Backbone.Router.extend({
      routes: {
        "": "skus_index",
        "skus": "skus_index",
        "purchace_orders": "purchace_orders_index",
        "purchace_orders/new": "new_purchace_order",
        "purchace_orders/:id": "show_purchace_order",
        "purchace_orders/:id/edit": "edit_purchace_order"
      },
      skus_index: function() {
        return UpworkIntroApp.set_main_content_view("skus_index");
      },
      purchace_orders_index: function() {
        return UpworkIntroApp.set_main_content_view("purchace_orders_index");
      },
      show_purchace_order: function(id) {
        return UpworkIntroApp.set_main_content_view("purchace_order_show", id);
      },
      edit_purchace_order: function(id) {
        return UpworkIntroApp.set_main_content_view("purchace_order_edit", id);
      },
      new_purchace_order: function() {
        return UpworkIntroApp.set_main_content_view("purchace_order_edit");
      }
    });
    UpworkIntroApp.router = new UpworkIntroApp.Router;
    return Backbone.history.start();
  });

}).call(this);

