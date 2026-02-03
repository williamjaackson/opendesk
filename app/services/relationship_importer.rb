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

    begin
      csv = CSV.parse(content, headers: true)
    rescue CSV::MalformedCSVError => e
      return { created: 0, skipped: 0, errors: [ { row: nil, message: "Invalid CSV: #{e.message}" } ] }
    end

    result = { created: 0, skipped: 0, errors: [] }

    # Match columns by header name (singularized table names)
    current_table_header = @custom_table.name.singularize
    other_table_header = @other_table.name.singularize

    # Collect unique names from CSV first (only load records we actually need)
    current_names = csv.map { |row| row[current_table_header]&.strip }.compact.uniq
    other_names = csv.map { |row| row[other_table_header]&.strip }.compact.uniq

    # Build targeted lookup hashes (only for names in the CSV)
    current_table_lookup = build_display_name_lookup(@custom_table, current_names)
    other_table_lookup = build_display_name_lookup(@other_table, other_names)

    csv.each.with_index(2) do |row, row_number|
      current_table_name = row[current_table_header]&.strip
      other_table_name = row[other_table_header]&.strip

      if current_table_name.blank? || other_table_name.blank?
        result[:errors] << { row: row_number, message: "Missing #{current_table_header} or #{other_table_header} name" }
        next
      end

      # Find records by display name
      current_record = current_table_lookup[current_table_name]
      other_record = other_table_lookup[other_table_name]

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

  def build_display_name_lookup(table, names_to_find)
    return {} if names_to_find.empty?

    # Query records by their display name (first non-blank column value)
    # Using SQL for efficiency with large tables
    sql = <<~SQL
      SELECT
        cr.id as record_id,
        COALESCE(
          (SELECT cv.value
           FROM custom_values cv
           JOIN custom_columns cc ON cc.id = cv.custom_column_id
           WHERE cv.custom_record_id = cr.id
             AND cv.value IS NOT NULL
             AND cv.value != ''
           ORDER BY cc.position
           LIMIT 1),
          CONCAT('Record #', cr.id)
        ) as display_name
      FROM custom_records cr
      WHERE cr.custom_table_id = ?
    SQL

    results = ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.sanitize_sql([ sql, table.id ])
    )

    # Build lookup hash, filtering to only names we're looking for
    names_set = names_to_find.to_set
    lookup = {}
    record_ids = []

    results.rows.each do |record_id, display_name|
      next unless names_set.include?(display_name)
      record_ids << record_id

      if lookup.key?(display_name)
        existing = lookup[display_name]
        lookup[display_name] = existing.is_a?(Array) ? existing + [ record_id ] : [ existing, record_id ]
      else
        lookup[display_name] = record_id
      end
    end

    # Load actual record objects for the IDs we found
    records_by_id = table.custom_records.where(id: record_ids).index_by(&:id)

    # Replace IDs with record objects
    lookup.transform_values! do |value|
      if value.is_a?(Array)
        value.map { |id| records_by_id[id] }
      else
        records_by_id[value]
      end
    end

    lookup
  end
end
