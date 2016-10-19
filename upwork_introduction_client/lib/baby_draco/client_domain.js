(function() {
  (function(Model) {
    'use strict';
    window.persistedSaveThises = [];
    window.unpersistedSaveThises = [];
    Model.fullExtend = function(protoProps, staticProps) {
      var extended, k;
      extended = Model.extend.call(this, protoProps, staticProps);
      extended.prototype._super = this.prototype;
      if (protoProps.defaults) {
        for (k in this.prototype.defaults) {
          if (!extended.prototype.defaults[k]) {
            extended.prototype.defaults[k] = this.prototype.defaults[k];
          }
        }
      }
      return extended;
    };
  })(Backbone.Model);

  window.DracoClient = {};

  DracoClient.Model = Backbone.Model.fullExtend({
    draco_meta: {
      dataSyncInProgress: true
    },
    setInnerObjectKey: function(path, key, value) {
      var obj;
      obj = this.get(path);
      obj[key] = value;
      return this.set(path, obj);
    }
  });

  DracoClient.addInstanceMethods = function(model_instance) {
    model_instance.save = function(on_success) {
      var self;
      if (this.get('id')) {
        persistedSaveThises.push(this);
        self = this;
        return $.ajax({
          url: this.dracoDomain.apiRoot + "/" + (this.get('draco_meta').tableName) + "/" + (this.get('id')),
          method: "put",
          data: {
            payload: this.dracoAttributes()
          },
          success: function(data) {
            if (on_success) {
              return on_success(data);
            }
          }
        });
      } else {
        self = this;
        return $.ajax({
          url: this.dracoDomain.apiRoot + "/" + (this.get('draco_meta').tableName),
          method: "post",
          data: {
            payload: this.dracoAttributes()
          },
          success: function(data) {
            self.set('id', data.new_model_id);
            if (on_success) {
              return on_success(data);
            }
          }
        });
      }
    };
    model_instance.free = function(on_success) {
      var self;
      self = this;
      return $.ajax({
        url: this.dracoDomain.apiRoot + "/" + (this.get('draco_meta').tableName) + "/free",
        method: "post",
        data: {
          id: self.get('id')
        },
        success: function(data) {
          self.set('status', 'free');
          if (on_success) {
            return on_success(data);
          }
        }
      });
    };
    return model_instance.dracoAttributes = function() {
      var attrs;
      attrs = _.clone(model_instance.attributes);
      delete attrs["id"];
      delete attrs["draco_meta"];
      delete attrs["updated_at"];
      delete attrs["created_at"];
      return attrs;
    };
  };

  DracoClient.Collection = Backbone.Collection.extend({
    model: DracoClient.Model,
    free: function(identifiers) {
      var models;
      if (!_.isArray(identifiers)) {
        identifiers = [identifiers];
      }
      models = this.remove(identifiers);
      _.each(models, function(model) {
        return model.free();
      });
      this.trigger("update");
    }
  });

  DracoClient.restClientFactory = function(api_root) {
    var self;
    self = {
      apiRoot: api_root,
      restProtocols: {
        find: function(table_name, id, on_success) {
          var new_model_instance;
          new_model_instance = new DracoClient.Model({
            draco_meta: {
              dataSyncInProgress: true,
              tableName: table_name,
              isPersistedInDomain: false
            }
          });
          new_model_instance.dracoDomain = self;
          DracoClient.addInstanceMethods(new_model_instance);
          $.ajax({
            url: self.apiRoot + "/" + table_name + "/" + id,
            success: function(data) {
              new_model_instance.set(data);
              new_model_instance.setInnerObjectKey('draco_meta', 'dataSyncInProgress', false);
              new_model_instance.setInnerObjectKey('draco_meta', 'isPersistedInDomain', true);
              if (on_success) {
                return on_success();
              }
            }
          });
          return new_model_instance;
        },
        "new": function(table_name) {
          var new_model_instance;
          new_model_instance = new DracoClient.Model({
            draco_meta: {
              dataSyncInProgress: false,
              tableName: table_name,
              isPersistedInDomain: false
            }
          });
          new_model_instance.dracoDomain = self;
          DracoClient.addInstanceMethods(new_model_instance);
          return new_model_instance;
        },
        where: function(table_name, query_params, on_success) {
          var new_collection;
          query_params || (query_params = {});
          new_collection = new DracoClient.Collection;
          new_collection.on("add", function(model) {
            return DracoClient.addInstanceMethods(model);
          });
          $.ajax({
            url: self.apiRoot + "/" + table_name,
            method: "get",
            success: function(data) {
              var models;
              models = _.map(data, function(model_attrs) {
                var new_model_instance;
                new_model_instance = new DracoClient.Model({
                  draco_meta: {
                    dataSyncInProgress: true,
                    tableName: table_name,
                    isPersistedInDomain: false
                  }
                });
                new_model_instance.set(model_attrs);
                new_model_instance.dracoDomain = self;
                new_model_instance.on("change", function() {
                  new_collection.trigger("update");
                });
                return new_model_instance;
              });
              new_collection.add(models);
              if (on_success) {
                return on_success(data);
              }
            }
          });
          return new_collection;
        }
      }
    };
    return self;
  };

}).call(this);

