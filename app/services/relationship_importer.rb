require "csv"

class RelationshipImporter
  def initialize(custom_table, relationship, file)
    @custom_table = custom_table
    @relationship = relationship
    @file = file
    @is_source = relationship.source_table_id == custom_table.id
    @other_table = @is_source ? relationship.target_table : relationship.source_table
  end

  def import
    content = @file.read.force_encoding("UTF-8").sub(/\A\xEF\xBB\xBF/, "")
    csv = CSV.parse(content, headers: true)

    result = { created: 0, skipped: 0, errors: [] }

    # Match columns by header name (singularized table names)
    current_table_header = @custom_table.name.singularize
    other_table_header = @other_table.name.singularize

    csv.each.with_index(2) do |row, row_number|
      current_table_name = row[current_table_header]&.strip
      other_table_name = row[other_table_header]&.strip

      if current_table_name.blank? || other_table_name.blank?
        result[:errors] << { row: row_number, message: "Missing #{current_table_header} or #{other_table_header} name" }
        next
      end

      # Find records by display name
      current_record = find_record_by_display_name(@custom_table, current_table_name)
      other_record = find_record_by_display_name(@other_table, other_table_name)

      if current_record.nil?
        result[:errors] << { row: row_number, message: "No record found matching '#{current_table_name}' in #{@custom_table.name}" }
        next
      end

      if other_record.nil?
        result[:errors] << { row: row_number, message: "No record found matching '#{other_table_name}' in #{@other_table.name}" }
        next
      end

      if current_record.is_a?(Array)
        result[:errors] << { row: row_number, message: "Multiple records match '#{current_table_name}' in #{@custom_table.name}" }
        next
      end

      if other_record.is_a?(Array)
        result[:errors] << { row: row_number, message: "Multiple records match '#{other_table_name}' in #{@other_table.name}" }
        next
      end

      # Create the link - determine source/target based on relationship direction
      if @is_source
        link = CustomRecordLink.new(
          custom_relationship: @relationship,
          source_record: current_record,
          target_record: other_record
        )
      else
        link = CustomRecordLink.new(
          custom_relationship: @relationship,
          source_record: other_record,
          target_record: current_record
        )
      end

      if link.save
        result[:created] += 1
      else
        if link.errors[:target_record_id]&.include?("has already been taken")
          result[:skipped] += 1
        else
          result[:errors] << { row: row_number, message: link.errors.full_messages.join(", ") }
        end
      end
    end

    result
  end

  private

  def find_record_by_display_name(table, name)
    # Get all records and check their display names
    # This is not the most efficient but display_name is computed
    matches = table.custom_records.includes(custom_values: :custom_column).select do |record|
      record.display_name == name
    end

    case matches.size
    when 0 then nil
    when 1 then matches.first
    else matches # Return array to indicate ambiguity
    end
  end
end
