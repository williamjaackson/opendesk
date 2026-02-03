class AddProtectedToCustomTables < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_tables, :protected, :boolean, default: false, null: false
  end
end
