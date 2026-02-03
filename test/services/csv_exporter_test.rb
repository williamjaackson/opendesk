require "test_helper"

class CsvExporterTest < ActiveSupport::TestCase
  setup do
    @table = custom_tables(:contacts)
    @exporter = CsvExporter.new(@table)
  end

  test "headers include column names" do
    headers = @exporter.headers
    assert_includes headers, "Name"
    assert_includes headers, "Email"
  end

  test "headers do not include ID column" do
    headers = @exporter.headers
    refute_includes headers, "ID"
  end

  test "can filter to specific columns" do
    column = custom_columns(:name)
    exporter = CsvExporter.new(@table, columns: [ column ])
    headers = exporter.headers
    assert_equal [ "Name" ], headers
  end

  test "generate produces valid CSV with BOM" do
    csv_content = @exporter.generate.to_a.join
    assert csv_content.start_with?(CsvExporter::UTF8_BOM)
  end

  test "generate includes record data" do
    csv_content = @exporter.generate.to_a.join
    assert_includes csv_content, "Alice Smith"
  end

  test "generate_template produces headers only" do
    template = @exporter.generate_template.to_a.join
    lines = template.lines
    assert_equal 1, lines.count
  end

  test "generate_template marks computed columns" do
    column = @table.custom_columns.create!(
      name: "Full Name",
      column_type: "computed",
      formula: "{Name}",
      result_type: "text",
      position: 100
    )

    template = @exporter.generate_template.to_a.join
    assert_includes template, "Full Name (computed)"
  end

  test "formats boolean values as Yes/No" do
    record = custom_records(:alice)
    column = custom_columns(:boolean)
    record.custom_values.find_or_create_by!(custom_column: column) do |cv|
      cv.value = "1"
    end

    csv_content = @exporter.generate.to_a.join
    assert_includes csv_content, "Yes"
  end

  test "generate_relationship creates CSV with linked records" do
    relationship = CustomRelationship.create!(
      name: "Assigned Deals",
      inverse_name: "Assigned Contact",
      kind: "one_to_many",
      source_table: @table,
      target_table: custom_tables(:deals)
    )

    csv_content = @exporter.generate_relationship(relationship).to_a.join
    assert_includes csv_content, "Contact"
    assert_includes csv_content, "Deal"
  end
end
