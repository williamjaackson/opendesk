class RenameRelationshipKinds < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE custom_relationships SET kind = 'one_to_one' WHERE kind = 'has_one';
      UPDATE custom_relationships SET kind = 'one_to_many' WHERE kind = 'has_many';
    SQL
  end

  def down
    execute <<~SQL
      UPDATE custom_relationships SET kind = 'has_one' WHERE kind = 'one_to_one';
      UPDATE custom_relationships SET kind = 'has_many' WHERE kind = 'one_to_many';
      UPDATE custom_relationships SET kind = 'has_many' WHERE kind = 'many_to_one';
    SQL
  end
end
