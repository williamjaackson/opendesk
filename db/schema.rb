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

ActiveRecord::Schema[8.1].define(version: 2026_02_02_052350) do
  create_table "custom_columns", force: :cascade do |t|
    t.string "column_type", null: false
    t.datetime "created_at", null: false
    t.integer "custom_table_id", null: false
    t.text "formula"
    t.integer "linked_column_id"
    t.string "name", null: false
    t.json "options"
    t.integer "position", default: 0, null: false
    t.string "regex_label"
    t.string "regex_pattern"
    t.boolean "required", default: false, null: false
    t.string "result_type"
    t.boolean "show_on_preview", default: true
    t.datetime "updated_at", null: false
    t.index ["custom_table_id", "position"], name: "index_custom_columns_on_custom_table_id_and_position"
    t.index ["custom_table_id"], name: "index_custom_columns_on_custom_table_id"
    t.index ["linked_column_id"], name: "index_custom_columns_on_linked_column_id"
  end

  create_table "custom_record_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "custom_relationship_id", null: false
    t.integer "source_record_id", null: false
    t.integer "target_record_id", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_relationship_id", "source_record_id", "target_record_id"], name: "idx_record_links_uniqueness", unique: true
    t.index ["custom_relationship_id"], name: "index_custom_record_links_on_custom_relationship_id"
    t.index ["source_record_id"], name: "index_custom_record_links_on_source_record_id"
    t.index ["target_record_id"], name: "index_custom_record_links_on_target_record_id"
  end

  create_table "custom_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "custom_table_id", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_table_id"], name: "index_custom_records_on_custom_table_id"
  end

  create_table "custom_relationships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "inverse_name", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "source_table_id", null: false
    t.boolean "symmetric", default: false, null: false
    t.integer "target_table_id", null: false
    t.datetime "updated_at", null: false
    t.index ["source_table_id", "name"], name: "index_custom_relationships_on_source_table_id_and_name", unique: true
    t.index ["source_table_id", "position"], name: "index_custom_relationships_on_source_table_id_and_position"
    t.index ["source_table_id"], name: "index_custom_relationships_on_source_table_id"
    t.index ["target_table_id", "inverse_name"], name: "index_custom_relationships_on_target_table_id_and_inverse_name", unique: true
    t.index ["target_table_id"], name: "index_custom_relationships_on_target_table_id"
  end

  create_table "custom_tables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "organisation_id", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.integer "table_group_id"
    t.datetime "updated_at", null: false
    t.index ["organisation_id", "position"], name: "index_custom_tables_on_organisation_id_and_position"
    t.index ["organisation_id", "slug"], name: "index_custom_tables_on_organisation_id_and_slug", unique: true
    t.index ["organisation_id"], name: "index_custom_tables_on_organisation_id"
    t.index ["table_group_id"], name: "index_custom_tables_on_table_group_id"
  end

  create_table "custom_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "custom_column_id", null: false
    t.integer "custom_record_id", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["custom_column_id", "value"], name: "index_custom_values_on_custom_column_id_and_value"
    t.index ["custom_column_id"], name: "index_custom_values_on_custom_column_id"
    t.index ["custom_record_id", "custom_column_id"], name: "index_custom_values_on_custom_record_id_and_custom_column_id", unique: true
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
    t.string "theme_colour"
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

  create_table "table_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "organisation_id", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id", "position"], name: "index_table_groups_on_organisation_id_and_position"
    t.index ["organisation_id", "slug"], name: "index_table_groups_on_organisation_id_and_slug", unique: true
    t.index ["organisation_id"], name: "index_table_groups_on_organisation_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "custom_columns", "custom_columns", column: "linked_column_id"
  add_foreign_key "custom_columns", "custom_tables"
  add_foreign_key "custom_record_links", "custom_records", column: "source_record_id"
  add_foreign_key "custom_record_links", "custom_records", column: "target_record_id"
  add_foreign_key "custom_record_links", "custom_relationships"
  add_foreign_key "custom_records", "custom_tables"
  add_foreign_key "custom_relationships", "custom_tables", column: "source_table_id"
  add_foreign_key "custom_relationships", "custom_tables", column: "target_table_id"
  add_foreign_key "custom_tables", "organisations"
  add_foreign_key "custom_tables", "table_groups"
  add_foreign_key "custom_values", "custom_columns"
  add_foreign_key "custom_values", "custom_records"
  add_foreign_key "organisation_users", "organisations"
  add_foreign_key "organisation_users", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "table_groups", "organisations"
end
