class EvaluateComputedColumnJob < ApplicationJob
  queue_as :default

  def perform(custom_table_id, computed_column_ids)
    custom_table = CustomTable.find(custom_table_id)
    computed_columns = custom_table.custom_columns.where(id: computed_column_ids).order(:position)
    return if computed_columns.empty?

    all_columns = custom_table.custom_columns.order(:position)
    custom_table.custom_records.includes(custom_values: :custom_column).find_each do |record|
      FormulaEvaluator.evaluate_record(record, computed_columns, all_columns: all_columns)
    end
  rescue ActiveRecord::RecordNotFound
    # Table or column was deleted
  end
end
