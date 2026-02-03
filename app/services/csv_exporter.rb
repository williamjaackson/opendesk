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
    rel_name = relationship_name_for(@custom_table, relationship)
    other_table = relationship.source_table_id == @custom_table.id ? relationship.target_table : relationship.source_table
    is_source = relationship.source_table_id == @custom_table.id

    Enumerator.new do |yielder|
      yielder << UTF8_BOM
      yielder << CSV.generate_line([
        "#{@custom_table.name.singularize}",
        "#{other_table.name.singularize}"
      ])

      @custom_table.custom_records.includes(:source_record_links, :target_record_links).find_each do |record|
        linked = record.linked_records_for(relationship)
        linked.each do |linked_record|
          yielder << CSV.generate_line([
            record.display_name,
            linked_record.display_name
          ])
        end
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

  def relationship_name_for(table, relationship)
    if relationship.source_table_id == table.id
      relationship.name
    else
      relationship.inverse_name
    end
  end
end
