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

    csv.each.with_index(2) do |row, row_number|
      source_name = row[0]&.strip
      target_name = row[1]&.strip

      if source_name.blank? || target_name.blank?
        result[:errors] << { row: row_number, message: "Missing source or target name" }
        next
      end

      # Find records by display name
      source_record = find_record_by_display_name(@custom_table, source_name)
      target_record = find_record_by_display_name(@other_table, target_name)

      if source_record.nil?
        result[:errors] << { row: row_number, message: "No record found matching '#{source_name}' in #{@custom_table.name}" }
        next
      end

      if target_record.nil?
        result[:errors] << { row: row_number, message: "No record found matching '#{target_name}' in #{@other_table.name}" }
        next
      end

      if source_record.is_a?(Array)
        result[:errors] << { row: row_number, message: "Multiple records match '#{source_name}' in #{@custom_table.name}" }
        next
      end

      if target_record.is_a?(Array)
        result[:errors] << { row: row_number, message: "Multiple records match '#{target_name}' in #{@other_table.name}" }
        next
      end

      # Create the link (swap source/target if we're coming from the target side)
      if @is_source
        link = CustomRecordLink.new(
          custom_relationship: @relationship,
          source_record: source_record,
          target_record: target_record
        )
      else
        link = CustomRecordLink.new(
          custom_relationship: @relationship,
          source_record: target_record,
          target_record: source_record
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
