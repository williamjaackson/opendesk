class DestroyTableJob < ApplicationJob
  queue_as :default

  def perform(custom_table_id)
    custom_table = CustomTable.find(custom_table_id)

    # Delete in order to avoid foreign key issues
    # 1. Delete all record links (from relationships where this table is involved)
    relationship_ids = CustomRelationship.where(source_table_id: custom_table_id)
      .or(CustomRelationship.where(target_table_id: custom_table_id))
      .pluck(:id)

    CustomRecordLink.where(custom_relationship_id: relationship_ids).in_batches(of: 1000).delete_all

    # 2. Delete all relationships
    CustomRelationship.where(id: relationship_ids).delete_all

    # 3. Delete all custom values
    record_ids = custom_table.custom_records.pluck(:id)
    CustomValue.where(custom_record_id: record_ids).in_batches(of: 1000).delete_all

    # 4. Delete all records
    custom_table.custom_records.in_batches(of: 1000).delete_all

    # 5. Delete all columns (no dependent data left)
    custom_table.custom_columns.delete_all

    # 6. Delete CSV imports
    custom_table.csv_imports.delete_all

    # 7. Finally delete the table itself
    custom_table.delete
  rescue ActiveRecord::RecordNotFound
    # Table was already deleted
  end
end
