require "csv"

class CsvExporter
  UTF8_BOM = "\xEF\xBB\xBF"

  def initialize(custom_table, columns: nil)
    @custom_table = custom_table
    @columns = columns
  end

  def generate
    Enumerator.new do |yielder|
      yielder << UTF8_BOM
      yielder << CSV.generate_line(headers)

      @custom_table.custom_records.find_each do |record|
        yielder << CSV.generate_line(row_for(record))
      end
    end
  end

  def headers
    columns.map(&:name)
  end

  def generate_template
    template_headers = columns.map do |column|
      column.computed? ? "#{column.name} (computed)" : column.name
    end

    Enumerator.new do |yielder|
      yielder << UTF8_BOM
      yielder << CSV.generate_line(template_headers)
    end
  end

  def generate_relationship(relationship)
    other_table = relationship.source_table_id == @custom_table.id ? relationship.target_table : relationship.source_table
    is_source = relationship.source_table_id == @custom_table.id

    Enumerator.new do |yielder|
      yielder << UTF8_BOM
      yielder << CSV.generate_line([
        @custom_table.name.singularize,
        other_table.name.singularize
      ])

      links = CustomRecordLink.where(custom_relationship: relationship)
      all_record_ids = links.pluck(:source_record_id, :target_record_id).flatten.uniq
      display_names = batch_load_display_names(all_record_ids)

      links.find_each do |link|
        if is_source
          current_name = display_names[link.source_record_id]
          other_name = display_names[link.target_record_id]
        else
          current_name = display_names[link.target_record_id]
          other_name = display_names[link.source_record_id]
        end

        yielder << CSV.generate_line([ current_name, other_name ])
      end
    end
  end

  private

  def columns
    @columns ||= @custom_table.custom_columns.order(:position)
  end

  def row_for(record)
    values_by_column = record.custom_values.index_by(&:custom_column_id)

    columns.map do |column|
      value = values_by_column[column.id]&.value
      format_value(column, value)
    end
  end

  def format_value(column, value)
    return "" if value.blank?

    case column.column_type
    when "boolean"
      value == "1" ? "Yes" : "No"
    else
      value
    end
  end

  def batch_load_display_names(record_ids)
    return {} if record_ids.empty?

    sql = <<~SQL
      SELECT DISTINCT ON (cv.custom_record_id)
        cv.custom_record_id,
        COALESCE(NULLIF(cv.value, ''), CONCAT('Record #', cv.custom_record_id)) as display_name
      FROM custom_values cv
      JOIN custom_columns cc ON cc.id = cv.custom_column_id
      WHERE cv.custom_record_id IN (?)
        AND cv.value IS NOT NULL
        AND cv.value != ''
      ORDER BY cv.custom_record_id, cc.position
    SQL

    results = ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.sanitize_sql([ sql, record_ids ])
    )

    names = results.rows.to_h { |row| [ row[0], row[1] ] }
    record_ids.each { |id| names[id] ||= "Record ##{id}" }
    names
  end
end
