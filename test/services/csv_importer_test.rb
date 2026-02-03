require "test_helper"

class CsvImporterTest < ActiveSupport::TestCase
  setup do
    @table = custom_tables(:contacts)
  end

  test "parse_headers extracts headers from CSV" do
    csv_import = create_import_with_file("Name,Email\nAlice,alice@example.com")
    importer = CsvImporter.new(csv_import)

    headers = importer.parse_headers
    assert_equal %w[Name Email], headers
  end

  test "parse_headers handles UTF-8 BOM" do
    csv_import = create_import_with_file("\xEF\xBB\xBFName,Email\nAlice,alice@example.com")
    importer = CsvImporter.new(csv_import)

    headers = importer.parse_headers
    assert_equal %w[Name Email], headers
  end

  test "preview_rows returns first rows" do
    csv_import = create_import_with_file("Name,Email\nAlice,alice@example.com\nBob,bob@example.com")
    importer = CsvImporter.new(csv_import)

    rows = importer.preview_rows(limit: 1)
    assert_equal 1, rows.count
    assert_equal "Alice", rows.first["Name"]
  end

  test "count_rows returns total row count" do
    csv_import = create_import_with_file("Name,Email\nAlice,alice@example.com\nBob,bob@example.com\nCharlie,charlie@example.com")
    importer = CsvImporter.new(csv_import)

    assert_equal 3, importer.count_rows
  end

  test "import_row creates new record with mapped columns" do
    column = custom_columns(:name)
    csv_import = create_import_with_file("Name\nNewPerson")
    csv_import.update!(column_mapping: { "Name" => column.id.to_s })
    importer = CsvImporter.new(csv_import)

    row = { "Name" => "NewPerson" }
    result = importer.import_row(row)

    assert result.success
    assert_equal "NewPerson", result.record.custom_values.find_by(custom_column: column).value
  end

  test "import_row skips when duplicate_handling is skip and ID exists" do
    existing_record = custom_records(:alice)
    csv_import = create_import_with_file("ID,Name\n#{existing_record.id},Updated")
    csv_import.update!(
      column_mapping: { "ID" => "__id__", "Name" => custom_columns(:name).id.to_s },
      duplicate_handling: "skip"
    )
    importer = CsvImporter.new(csv_import)

    row = { "ID" => existing_record.id.to_s, "Name" => "Updated" }
    result = importer.import_row(row)

    assert_not result.success
    assert_includes result.errors.first, "Skipped"
  end

  test "import_row updates when duplicate_handling is update and ID exists" do
    existing_record = custom_records(:alice)
    column = custom_columns(:name)
    existing_record.custom_values.find_or_create_by!(custom_column: column) do |cv|
      cv.value = "Original"
    end

    csv_import = create_import_with_file("ID,Name\n#{existing_record.id},Updated")
    csv_import.update!(
      column_mapping: { "ID" => "__id__", "Name" => column.id.to_s },
      duplicate_handling: "update"
    )
    importer = CsvImporter.new(csv_import)

    row = { "ID" => existing_record.id.to_s, "Name" => "Updated" }
    result = importer.import_row(row)

    assert result.success
    existing_record.reload
    assert_equal "Updated", existing_record.custom_values.find_by(custom_column: column).value
  end

  test "import_row parses boolean values" do
    column = custom_columns(:boolean)
    csv_import = create_import_with_file("Active\nYes")
    csv_import.update!(column_mapping: { "Active" => column.id.to_s })
    importer = CsvImporter.new(csv_import)

    row = { "Active" => "Yes" }
    result = importer.import_row(row)

    assert result.success
    assert_equal "1", result.record.custom_values.find_by(custom_column: column).value
  end

  test "import_all processes all rows" do
    column = custom_columns(:name)
    csv_import = create_import_with_file("Name\nPerson1\nPerson2\nPerson3")
    csv_import.update!(
      status: "processing",
      column_mapping: { "Name" => column.id.to_s }
    )
    importer = CsvImporter.new(csv_import)

    assert_difference -> { @table.custom_records.count }, 3 do
      importer.import_all
    end

    csv_import.reload
    assert_equal 3, csv_import.total_rows
    assert_equal 3, csv_import.processed_rows
    assert_equal 3, csv_import.success_count
    assert_equal 0, csv_import.error_count
  end

  test "import_all tracks errors per row" do
    column = custom_columns(:email)
    csv_import = create_import_with_file("Email\ninvalid-email\nvalid@example.com")
    csv_import.update!(
      status: "processing",
      column_mapping: { "Email" => column.id.to_s }
    )
    importer = CsvImporter.new(csv_import)

    importer.import_all

    csv_import.reload
    assert_equal 1, csv_import.error_count
    assert_equal 1, csv_import.success_count
    assert csv_import.errors_log.any? { |e| e["row"] == 2 || e[:row] == 2 }
  end

  private

  def create_import_with_file(csv_content)
    csv_import = @table.csv_imports.new(status: "pending")
    csv_import.file.attach(
      io: StringIO.new(csv_content),
      filename: "test.csv",
      content_type: "text/csv"
    )
    csv_import.save!
    csv_import
  end
end
