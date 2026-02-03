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

  def create_columns_from_mapping!
    @column_mapping.each do |csv_header, mapping|
      next if mapping["action"] == "skip"
      next if mapping["action"] == "existing"

      if mapping["action"] == "create"
        column = @custom_table.custom_columns.create!(
          name: mapping["name"].presence || csv_header,
          column_type: mapping["type"] || "text",
          position: @custom_table.custom_columns.maximum(:position).to_i + 1
        )
        mapping["column_id"] = column.id
      end
    end
    @csv_import.update!(column_mapping: @column_mapping)
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

    @csv_import.status = "completed"
    @csv_import.save!
  end

  def import_row(row)
    record = @custom_table.custom_records.new

    @column_mapping.each do |csv_header, mapping|
      next if mapping["action"] == "skip"

      column_id = mapping["column_id"]&.to_i
      next unless column_id

      column = @custom_table.custom_columns.find_by(id: column_id)
      next unless column
      next if column.computed?

      csv_value = row[csv_header]
      value = parse_value(column, csv_value)

      record.custom_values.build(custom_column: column, value: value)
    end

    if record.save
      Result.new(success: true, record: record)
    else
      errors = collect_errors(record)
      Result.new(success: false, errors: errors)
    end
  end

  private

  def parse_value(column, csv_value)
    return nil if csv_value.blank?

    case column.column_type
    when "boolean"
      csv_value.to_s.downcase.in?(%w[yes true 1 y]) ? "1" : "0"
    else
      csv_value.to_s.strip
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
