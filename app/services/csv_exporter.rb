require "csv"

class CsvExporter
  UTF8_BOM = "\xEF\xBB\xBF"

  def initialize(custom_table)
    @custom_table = custom_table
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
    result = [ "ID" ]

    columns.each do |column|
      result << column.name
    end

    relationships.each do |relationship|
      name = relationship_name_for(@custom_table, relationship)
      result << "#{name} (ID)"
      result << "#{name} (Name)"
    end

    result
  end

  def template_headers
    result = [ "ID" ]

    columns.each do |column|
      if column.computed?
        result << "#{column.name} (computed)"
      else
        result << column.name
      end
    end

    relationships.each do |relationship|
      name = relationship_name_for(@custom_table, relationship)
      result << "#{name} (ID)"
      result << "#{name} (Name)"
    end

    result
  end

  def generate_template
    Enumerator.new do |yielder|
      yielder << UTF8_BOM
      yielder << CSV.generate_line(template_headers)
    end
  end

  private

  def columns
    @columns ||= @custom_table.custom_columns.order(:position)
  end

  def relationships
    @relationships ||= @custom_table.all_relationships.includes(:source_table, :target_table)
  end

  def row_for(record)
    values_by_column = record.custom_values.index_by(&:custom_column_id)
    result = [ record.id ]

    columns.each do |column|
      value = values_by_column[column.id]&.value
      result << format_value(column, value)
    end

    relationships.each do |relationship|
      linked = record.linked_records_for(relationship)
      result << linked.map(&:id).join("; ")
      result << linked.map(&:display_name).join("; ")
    end

    result
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
