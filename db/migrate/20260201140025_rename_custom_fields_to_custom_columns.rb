class RenameCustomFieldsToCustomColumns < ActiveRecord::Migration[8.1]
  def change
    rename_column :custom_fields, :field_type, :column_type
    rename_column :custom_values, :custom_field_id, :custom_column_id
    rename_table :custom_fields, :custom_columns
  end
end
