# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_31_012033) do
  create_table "custom_fields", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "custom_table_id", null: false
    t.string "field_type", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "required", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["custom_table_id", "position"], name: "index_custom_fields_on_custom_table_id_and_position"
    t.index ["custom_table_id"], name: "index_custom_fields_on_custom_table_id"
  end

  create_table "custom_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "custom_table_id", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_table_id"], name: "index_custom_records_on_custom_table_id"
  end

  create_table "custom_tables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "organisation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_custom_tables_on_organisation_id"
  end

  create_table "custom_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "custom_field_id", null: false
    t.integer "custom_record_id", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["custom_field_id", "value"], name: "index_custom_values_on_custom_field_id_and_value"
    t.index ["custom_field_id"], name: "index_custom_values_on_custom_field_id"
    t.index ["custom_record_id", "custom_field_id"], name: "index_custom_values_on_custom_record_id_and_custom_field_id", unique: true
    t.index ["custom_record_id"], name: "index_custom_values_on_custom_record_id"
  end

  create_table "organisation_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "organisation_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["organisation_id"], name: "index_organisation_users_on_organisation_id"
    t.index ["user_id"], name: "index_organisation_users_on_user_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "custom_fields", "custom_tables"
  add_foreign_key "custom_records", "custom_tables"
  add_foreign_key "custom_tables", "organisations"
  add_foreign_key "custom_values", "custom_fields"
  add_foreign_key "custom_values", "custom_records"
  add_foreign_key "organisation_users", "organisations"
  add_foreign_key "organisation_users", "users"
  add_foreign_key "sessions", "users"
end
