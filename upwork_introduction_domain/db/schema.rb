# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161013164710) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "line_items", force: :cascade do |t|
    t.string   "name"
    t.integer  "quantity"
    t.float    "price_per_unit"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "purchace_order_id"
    t.integer  "sku_id"
    t.string   "sku_cache"
  end

  create_table "purchace_orders", force: :cascade do |t|
    t.string   "supply_company_name"
    t.string   "supply_company_street_address"
    t.string   "supply_company_city"
    t.string   "supply_company_state"
    t.string   "supply_company_zip"
    t.string   "supply_company_email"
    t.string   "supply_company_phone"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.boolean  "has_been_received"
    t.datetime "received_at"
    t.datetime "placed_at"
    t.datetime "expected_to_arive_at"
  end

  create_table "skus", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "sku"
    t.string   "name"
  end

end
