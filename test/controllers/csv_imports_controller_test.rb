require "test_helper"

class CsvImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    @table = custom_tables(:contacts)
  end

  test "should get new" do
    get new_table_csv_import_path(@table)
    assert_response :success
  end

  test "should create csv_import with file" do
    file = fixture_file_upload("test.csv", "text/csv")

    assert_difference -> { CsvImport.count }, 1 do
      post table_csv_imports_path(@table), params: { csv_import: { file: file } }
    end

    csv_import = CsvImport.last
    assert_equal "mapping", csv_import.status
    assert_redirected_to table_csv_import_path(@table, csv_import)
  end

  test "should not create csv_import without file" do
    assert_no_difference -> { CsvImport.count } do
      post table_csv_imports_path(@table), params: { csv_import: { file: nil } }
    end
    assert_response :unprocessable_entity
  end

  test "should show mapping view when status is mapping" do
    csv_import = create_csv_import(status: "mapping")
    get table_csv_import_path(@table, csv_import)
    assert_response :success
  end

  test "should show progress view when status is processing" do
    csv_import = create_csv_import(status: "processing")
    get table_csv_import_path(@table, csv_import)
    assert_response :success
  end

  test "should show completed view when status is completed" do
    csv_import = create_csv_import(status: "completed")
    get table_csv_import_path(@table, csv_import)
    assert_response :success
  end

  test "should update column mapping and start import" do
    csv_import = create_csv_import(status: "mapping")
    column = custom_columns(:name)

    patch table_csv_import_path(@table, csv_import), params: {
      column_mapping: { "Name" => column.id.to_s },
      duplicate_handling: "create"
    }

    csv_import.reload
    assert_equal "completed", csv_import.status
    assert_redirected_to table_csv_import_path(@table, csv_import)
  end

  test "should destroy csv_import" do
    csv_import = create_csv_import

    assert_difference -> { CsvImport.count }, -1 do
      delete table_csv_import_path(@table, csv_import)
    end

    assert_redirected_to table_path(@table)
  end

  private

  def create_csv_import(status: "pending")
    csv_import = @table.csv_imports.new(status: status)
    csv_import.file.attach(
      io: StringIO.new("Name\nAlice\nBob"),
      filename: "test.csv",
      content_type: "text/csv"
    )
    csv_import.save!
    csv_import
  end
end
