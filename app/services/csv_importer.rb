require "csv"

class CsvImporter
  Result = Struct.new(:success, :record, :errors, keyword_init: true)

  def initialize(csv_import)
    @csv_import = csv_import
    @custom_table = csv_import.custom_table
    @column_mapping = csv_import.column_mapping || {}
  end

  def parse_headers
    content = @csv_import.file.download
    content = content.force_encoding("UTF-8").sub(/\A\xEF\xBB\xBF/, "")
    csv = CSV.parse(content, headers: true)
    csv.headers.compact
  rescue CSV::MalformedCSVError => e
    raise ArgumentError, "Invalid CSV file: #{e.message}"
  end

  def preview_rows(limit: 5)
    content = @csv_import.file.download
    content = content.force_encoding("UTF-8").sub(/\A\xEF\xBB\xBF/, "")
    csv = CSV.parse(content, headers: true)
    csv.first(limit).map(&:to_h)
  end

  def count_rows
    content = @csv_import.file.download
    content = content.force_encoding("UTF-8").sub(/\A\xEF\xBB\xBF/, "")
    CSV.parse(content, headers: true).count
  end

  def import_all
    content = @csv_import.file.download
    content = content.force_encoding("UTF-8").sub(/\A\xEF\xBB\xBF/, "")
    csv = CSV.parse(content, headers: true)

    @csv_import.update!(total_rows: csv.count, processed_rows: 0, success_count: 0, error_count: 0, errors_log: [])

    csv.each.with_index(2) do |row, row_number|
      result = import_row(row)

      if result.success
        @csv_import.success_count += 1
      else
        @csv_import.add_error(row_number, result.errors.join(", "))
      end

      @csv_import.processed_rows += 1
      @csv_import.save! if (@csv_import.processed_rows % 50).zero?
    end

    @csv_import.status = @csv_import.error_count.zero? ? "completed" : "completed"
    @csv_import.save!
  end

  def import_row(row)
    id_column = @column_mapping.key("__id__")
    record_id = id_column ? row[id_column] : nil

    record = find_or_initialize_record(record_id)
    return Result.new(success: false, errors: [ "Skipped (ID exists)" ]) if record.nil?

    set_column_values(record, row)
    set_relationship_links(record, row)

    if record.save
      Result.new(success: true, record: record)
    else
      errors = collect_errors(record)
      Result.new(success: false, errors: errors)
    end
  end

  private

  def find_or_initialize_record(record_id)
    case @csv_import.duplicate_handling
    when "create"
      @custom_table.custom_records.new
    when "skip"
      if record_id.present? && @custom_table.custom_records.exists?(id: record_id)
        nil
      else
        @custom_table.custom_records.new
      end
    when "update"
      if record_id.present?
        @custom_table.custom_records.find_by(id: record_id) || @custom_table.custom_records.new
      else
        @custom_table.custom_records.new
      end
    else
      @custom_table.custom_records.new
    end
  end

  def set_column_values(record, row)
    columns_by_id = @custom_table.custom_columns.index_by(&:id)

    @column_mapping.each do |csv_header, target|
      next if target == "__id__" || target.blank?
      next if target.to_s.start_with?("rel:")

      column_id = target.to_i
      column = columns_by_id[column_id]
      next unless column
      next if column.computed?

      csv_value = row[csv_header]
      value = parse_value(column, csv_value)

      if record.persisted?
        existing = record.custom_values.find_by(custom_column_id: column_id)
        if existing
          existing.update!(value: value)
        else
          record.custom_values.create!(custom_column: column, value: value)
        end
      else
        record.custom_values.build(custom_column: column, value: value)
      end
    end
  end

  def parse_value(column, csv_value)
    return nil if csv_value.blank?

    case column.column_type
    when "boolean"
      csv_value.downcase.in?(%w[yes true 1 y]) ? "1" : "0"
    else
      csv_value.to_s.strip
    end
  end

  def set_relationship_links(record, row)
    return unless record.persisted?

    @column_mapping.each do |csv_header, target|
      next unless target.to_s.start_with?("rel:")

      relationship_id = target.sub("rel:", "").to_i
      relationship = CustomRelationship.find_by(id: relationship_id)
      next unless relationship

      csv_value = row[csv_header]
      next if csv_value.blank?

      target_ids = csv_value.split(";").map(&:strip).map(&:to_i).reject(&:zero?)
      link_records(record, relationship, target_ids)
    end
  end

  def link_records(record, relationship, target_ids)
    existing_links = record.source_record_links.where(custom_relationship: relationship)
    existing_links.destroy_all

    target_ids.each do |target_id|
      target_record = CustomRecord.find_by(id: target_id)
      next unless target_record

      CustomRecordLink.create(
        custom_relationship: relationship,
        source_record: record,
        target_record: target_record
      )
    end
  end

  def collect_errors(record)
    errors = record.errors.full_messages.dup

    record.custom_values.each do |value|
      if value.errors.any?
        column_name = value.custom_column&.name || "Unknown"
        value.errors.full_messages.each do |msg|
          errors << "#{column_name}: #{msg}"
        end
      end
    end

    errors
  end
end
