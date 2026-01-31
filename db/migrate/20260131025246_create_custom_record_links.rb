class CreateCustomRecordLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_record_links do |t|
      t.references :custom_relationship, null: false, foreign_key: true
      t.references :source_record, null: false, foreign_key: { to_table: :custom_records }
      t.references :target_record, null: false, foreign_key: { to_table: :custom_records }

      t.timestamps
    end

    add_index :custom_record_links, [ :custom_relationship_id, :source_record_id, :target_record_id ], unique: true, name: "idx_record_links_uniqueness"
  end
end
