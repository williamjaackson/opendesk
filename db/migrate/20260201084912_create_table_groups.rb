class CreateTableGroups < ActiveRecord::Migration[8.1]
  def up
    create_table :table_groups do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.references :organisation, null: false, foreign_key: true

      t.timestamps
    end

    add_index :table_groups, [ :organisation_id, :slug ], unique: true
    add_index :table_groups, [ :organisation_id, :position ]

    add_reference :custom_tables, :table_group, foreign_key: true

    # Backfill: create a default "Tables" group for each organisation and assign existing tables
    Organisation.find_each do |org|
      group = TableGroup.create!(name: "Tables", slug: "tables", position: 0, organisation: org)
      CustomTable.where(organisation_id: org.id).update_all(table_group_id: group.id)
    end
  end

  def down
    remove_reference :custom_tables, :table_group
    drop_table :table_groups
  end
end
