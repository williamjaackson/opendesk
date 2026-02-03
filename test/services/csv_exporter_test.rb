require "test_helper"

class CsvExporterTest < ActiveSupport::TestCase
  setup do
    @table = custom_tables(:contacts)
    @exporter = CsvExporter.new(@table)
  end

  test "headers include ID as first column" do
    headers = @exporter.headers
    assert_equal "ID", headers.first
  end

  test "headers include column names" do
    headers = @exporter.headers
    assert_includes headers, "Name"
    assert_includes headers, "Email"
  end

  test "headers include relationship columns with ID and Name" do
    @table.source_relationships.create!(
      name: "Assigned Deals",
      inverse_name: "Assigned Contact",
      kind: "one_to_many",
      target_table: custom_tables(:deals)
    )

    headers = @exporter.headers
    assert_includes headers, "Assigned Deals (ID)"
    assert_includes headers, "Assigned Deals (Name)"
  end

  test "template_headers marks computed columns" do
    column = @table.custom_columns.create!(
      name: "Full Name",
      column_type: "computed",
      formula: "{Name}",
      result_type: "text",
      position: 100
    )

    headers = @exporter.template_headers
    assert_includes headers, "Full Name (computed)"
  end

  test "generate produces valid CSV with BOM" do
    csv_content = @exporter.generate.to_a.join
    assert csv_content.start_with?(CsvExporter::UTF8_BOM)
  end

  test "generate includes record IDs" do
    record = @table.custom_records.first
    csv_content = @exporter.generate.to_a.join
    assert_includes csv_content, record.id.to_s
  end

  test "generate_template produces headers only" do
    template = @exporter.generate_template.to_a.join
    lines = template.lines
    assert_equal 1, lines.count
  end

  test "formats boolean values as Yes/No" do
    record = custom_records(:alice)
    column = custom_columns(:boolean)
    record.custom_values.create!(custom_column: column, value: "1")

    csv_content = @exporter.generate.to_a.join
    assert_includes csv_content, "Yes"
  end
end
