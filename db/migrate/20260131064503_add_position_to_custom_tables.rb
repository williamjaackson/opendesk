class AddPositionToCustomTables < ActiveRecord::Migration[8.1]
  def up
    add_column :custom_tables, :position, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE custom_tables
      SET position = (
        SELECT COUNT(*)
        FROM custom_tables AS ct
        WHERE ct.organisation_id = custom_tables.organisation_id
          AND ct.name < custom_tables.name
      )
    SQL

    add_index :custom_tables, [ :organisation_id, :position ]
  end

  def down
    remove_index :custom_tables, [ :organisation_id, :position ]
    remove_column :custom_tables, :position
  end
end
