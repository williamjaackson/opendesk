require "test_helper"

class CustomRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    @table = custom_tables(:contacts)
    @record = custom_records(:alice)
    @name_column = custom_columns(:name)
    @email_column = custom_columns(:email)
  end

  test "should get new" do
    get new_table_record_path(@table)
    assert_response :success
  end

  test "should create custom record" do
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should not create custom record with missing required fields" do
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @email_column.id.to_s => "charlie@example.com" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show custom record" do
    get table_record_path(@table, @record)
    assert_response :success
  end

  test "should get edit" do
    get edit_table_record_path(@table, @record)
    assert_response :success
  end

  test "should update custom record" do
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice Updated" } }
    assert_redirected_to table_record_path(@table, @record)
    assert_equal "Alice Updated", @record.custom_values.find_by(custom_column: @name_column).reload.value
  end

  test "should not update custom record with missing required fields" do
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy custom record" do
    assert_difference "CustomRecord.count", -1 do
      delete table_record_path(@table, @record)
    end

    assert_redirected_to table_path(@table)
  end

  test "should not create record with invalid number value" do
    number_column = custom_columns(:number)
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", number_column.id.to_s => "abc" } }
    end

    assert_response :unprocessable_entity
  end

  test "should create record with valid number value" do
    number_column = custom_columns(:number)
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", number_column.id.to_s => "123" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should not create record with invalid email value" do
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", @email_column.id.to_s => "notanemail" } }
    end

    assert_response :unprocessable_entity
  end

  test "should create record with valid email value" do
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", @email_column.id.to_s => "test@example.com" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should not update record with invalid number value" do
    number_column = custom_columns(:number)
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice", number_column.id.to_s => "abc" } }

    assert_response :unprocessable_entity
  end

  test "should not update record with invalid email value" do
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice", @email_column.id.to_s => "notanemail" } }

    assert_response :unprocessable_entity
  end

  test "should redirect when not managing" do
    stop_managing_organisation
    get edit_table_record_path(@table, @record)
    assert_redirected_to organisations_path
  end
end
