class CreateCsvImports < ActiveRecord::Migration[8.1]
  def change
    create_table :csv_imports do |t|
      t.references :custom_table, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :duplicate_handling, null: false, default: "create"
      t.json :column_mapping
      t.integer :total_rows, default: 0
      t.integer :processed_rows, default: 0
      t.integer :success_count, default: 0
      t.integer :error_count, default: 0
      t.json :errors_log
      t.timestamps
    end
  end
end
