class AddSymmetricToCustomRelationships < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_relationships, :symmetric, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE custom_relationships
          SET symmetric = TRUE, inverse_name = name
          WHERE kind = 'one_to_one'
            AND source_table_id = target_table_id
        SQL
      end
    end
  end
end
