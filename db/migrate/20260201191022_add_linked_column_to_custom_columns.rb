class AddLinkedColumnToCustomColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_columns, :linked_column_id, :integer
    add_index :custom_columns, :linked_column_id
    add_foreign_key :custom_columns, :custom_columns, column: :linked_column_id
  end
end
