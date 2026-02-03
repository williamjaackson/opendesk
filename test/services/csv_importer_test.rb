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
    csv_import.update!(column_mapping: {
      "Name" => { "action" => "existing", "column_id" => column.id.to_s }
    })
    importer = CsvImporter.new(csv_import)

    row = { "Name" => "NewPerson" }
    result = importer.import_row(row)

    assert result.success
    assert_equal "NewPerson", result.record.custom_values.find_by(custom_column: column).value
  end

  test "import_row parses boolean values" do
    column = custom_columns(:boolean)
    csv_import = create_import_with_file("Active\nYes")
    csv_import.update!(column_mapping: {
      "Active" => { "action" => "existing", "column_id" => column.id.to_s }
    })
    importer = CsvImporter.new(csv_import)

    row = { "Active" => "Yes" }
    result = importer.import_row(row)

    assert result.success
    assert_equal "1", result.record.custom_values.find_by(custom_column: column).value
  end

  test "import_row skips columns marked as skip" do
    column = custom_columns(:name)
    csv_import = create_import_with_file("Name,Other\nTest,Ignored")
    csv_import.update!(column_mapping: {
      "Name" => { "action" => "existing", "column_id" => column.id.to_s },
      "Other" => { "action" => "skip" }
    })
    importer = CsvImporter.new(csv_import)

    row = { "Name" => "Test", "Other" => "Ignored" }
    result = importer.import_row(row)

    assert result.success
    assert_equal 1, result.record.custom_values.count
  end

  test "import_all processes all rows" do
    column = custom_columns(:name)
    csv_import = create_import_with_file("Name\nPerson1\nPerson2\nPerson3")
    csv_import.update!(
      status: "processing",
      column_mapping: {
        "Name" => { "action" => "existing", "column_id" => column.id.to_s }
      }
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
      column_mapping: {
        "Email" => { "action" => "existing", "column_id" => column.id.to_s }
      }
    )
    importer = CsvImporter.new(csv_import)

    importer.import_all

    csv_import.reload
    assert_equal 1, csv_import.error_count
    assert_equal 1, csv_import.success_count
    assert csv_import.errors_log.any? { |e| e["row"] == 2 || e[:row] == 2 }
  end

  test "create_columns_from_mapping creates new columns" do
    csv_import = create_import_with_file("NewColumn\nValue")
    csv_import.update!(column_mapping: {
      "NewColumn" => { "action" => "create", "name" => "My New Column", "type" => "text" }
    })
    importer = CsvImporter.new(csv_import)

    assert_difference -> { @table.custom_columns.count }, 1 do
      importer.create_columns_from_mapping!
    end

    new_column = @table.custom_columns.find_by(name: "My New Column")
    assert_not_nil new_column
    assert_equal "text", new_column.column_type

    csv_import.reload
    assert_equal new_column.id, csv_import.column_mapping["NewColumn"]["column_id"]
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
