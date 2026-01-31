class CreateCustomValues < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_values do |t|
      t.references :custom_record, null: false, foreign_key: true
      t.references :custom_field, null: false, foreign_key: true
      t.text :value

      t.timestamps
    end

    add_index :custom_values, [ :custom_record_id, :custom_field_id ], unique: true
    add_index :custom_values, [ :custom_field_id, :value ]
  end
end
