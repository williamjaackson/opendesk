class BackfillColumnJob < ApplicationJob
  queue_as :default

  def perform(custom_table_id, custom_column_id, backfill_mode, backfill_value: nil, source_column_id: nil, backfill_fallback: nil)
    custom_table = CustomTable.find(custom_table_id)
    custom_column = custom_table.custom_columns.find(custom_column_id)

    case backfill_mode
    when "fixed"
      backfill_fixed(custom_table, custom_column, backfill_value)
    when "column"
      source_column = custom_table.custom_columns.find(source_column_id)
      backfill_from_column(custom_table, custom_column, source_column, backfill_fallback)
    end
  rescue ActiveRecord::RecordNotFound
    # Table or column was deleted
  end

  private

  def backfill_fixed(custom_table, custom_column, value)
    custom_table.custom_records.find_each do |record|
      record.custom_values.create!(custom_column: custom_column, value: value)
    end
  end

  def backfill_from_column(custom_table, custom_column, source_column, fallback)
    custom_table.custom_records.includes(:custom_values).find_each do |record|
      source_value = record.custom_values.find { |v| v.custom_column_id == source_column.id }
      value_to_use = source_value&.value.presence

      if value_to_use
        value_to_use = coerce_value(value_to_use, source_column.column_type, custom_column.column_type)
        new_value = record.custom_values.build(custom_column: custom_column, value: value_to_use)
        unless new_value.valid?
          if fallback.present?
            new_value.value = fallback
          else
            next
          end
        end
        new_value.save!
      elsif fallback.present?
        record.custom_values.create!(custom_column: custom_column, value: fallback)
      end
    end
  end

  def coerce_value(value, from_type, to_type)
    return value if from_type == to_type

    case to_type
    when "number"
      value.to_s.gsub(/[^\d-]/, "").presence
    when "decimal", "currency"
      value.to_s.gsub(/[^\d.-]/, "").presence
    when "boolean"
      %w[1 true yes].include?(value.to_s.downcase) ? "1" : "0"
    else
      value.to_s
    end
  end
end
