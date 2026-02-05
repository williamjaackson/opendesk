class AddDeletedAtToCustomTables < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_tables, :deleted_at, :datetime
    add_index :custom_tables, :deleted_at
  end
end
