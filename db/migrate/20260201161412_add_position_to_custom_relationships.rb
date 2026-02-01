class AddPositionToCustomRelationships < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_relationships, :position, :integer, null: false, default: 0
    add_index :custom_relationships, [ :source_table_id, :position ]
  end
end
