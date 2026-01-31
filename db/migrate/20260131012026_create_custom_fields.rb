class CreateCustomFields < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_fields do |t|
      t.references :custom_table, null: false, foreign_key: true
      t.string :name, null: false
      t.string :field_type, null: false
      t.boolean :required, null: false, default: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :custom_fields, [ :custom_table_id, :position ]
  end
end
