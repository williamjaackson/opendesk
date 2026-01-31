class CreateCustomRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_relationships do |t|
      t.references :source_table, null: false, foreign_key: { to_table: :custom_tables }
      t.references :target_table, null: false, foreign_key: { to_table: :custom_tables }
      t.string :name, null: false
      t.string :inverse_name, null: false
      t.string :kind, null: false

      t.timestamps
    end

    add_index :custom_relationships, [ :source_table_id, :name ], unique: true
    add_index :custom_relationships, [ :target_table_id, :inverse_name ], unique: true
  end
end
