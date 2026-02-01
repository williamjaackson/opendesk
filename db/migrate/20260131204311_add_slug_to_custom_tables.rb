class AddSlugToCustomTables < ActiveRecord::Migration[8.1]
  def up
    add_column :custom_tables, :slug, :string

    execute <<~SQL
      UPDATE custom_tables
      SET slug = LOWER(REPLACE(REPLACE(REPLACE(TRIM(name), ' ', '-'), '_', '-'), '--', '-'))
    SQL

    # Resolve duplicates by appending the row ID
    dupes = execute(<<~SQL)
      SELECT organisation_id, slug
      FROM custom_tables
      GROUP BY organisation_id, slug
      HAVING COUNT(*) > 1
    SQL

    dupes.each do |row|
      org_id, slug = row["organisation_id"], row["slug"]
      ids = execute("SELECT id FROM custom_tables WHERE organisation_id = #{org_id} AND slug = '#{slug}' ORDER BY id")
      ids.each_with_index do |id_row, i|
        next if i == 0
        execute("UPDATE custom_tables SET slug = '#{slug}-#{id_row['id']}' WHERE id = #{id_row['id']}")
      end
    end

    change_column_null :custom_tables, :slug, false
    add_index :custom_tables, [ :organisation_id, :slug ], unique: true
  end

  def down
    remove_index :custom_tables, [ :organisation_id, :slug ]
    remove_column :custom_tables, :slug
  end
end
