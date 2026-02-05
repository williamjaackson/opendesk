class DestroyColumnJob < ApplicationJob
  queue_as :default

  def perform(custom_column_id)
    custom_column = CustomColumn.find(custom_column_id)
    # Use unscoped in case table was soft-deleted during job execution
    custom_table = CustomTable.unscoped.find(custom_column.custom_table_id)

    # 1. Nullify any columns that link to this one
    CustomColumn.where(linked_column_id: custom_column_id).update_all(linked_column_id: nil)

    # 2. Delete all values for this column in batches
    custom_column.custom_values.in_batches(of: 1000).delete_all

    # 3. Delete the column itself
    custom_column.delete

    # 4. Cleanup empty records (records with no values left)
    # This replicates the after_destroy callback behavior
    cleanup_empty_records(custom_table)
  rescue ActiveRecord::RecordNotFound
    # Column was already deleted
  end

  private

  def cleanup_empty_records(custom_table)
    empty_records_scope = custom_table.custom_records
      .left_joins(:custom_values)
      .where(custom_values: { id: nil })

    empty_records_scope.in_batches(of: 1000) do |batch|
      batch_ids = batch.pluck(:id)
      next if batch_ids.empty?

      # Delete record links for empty records in this batch
      CustomRecordLink.where(source_record_id: batch_ids)
        .or(CustomRecordLink.where(target_record_id: batch_ids))
        .delete_all

      # Delete the empty records in this batch
      CustomRecord.where(id: batch_ids).delete_all
    end
  end
end
