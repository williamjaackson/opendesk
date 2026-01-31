require "test_helper"

class CustomRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    @table = custom_tables(:contacts)
    @record = custom_records(:alice)
    @name_field = custom_fields(:name)
    @email_field = custom_fields(:email)
  end

  test "should get new" do
    get new_custom_table_custom_record_path(@table)
    assert_response :success
  end

  test "should create custom record" do
    assert_difference "CustomRecord.count", 1 do
      post custom_table_custom_records_path(@table), params: { values: { @name_field.id.to_s => "Charlie" } }
    end

    assert_redirected_to custom_table_path(@table)
  end

  test "should not create custom record with missing required fields" do
    assert_no_difference "CustomRecord.count" do
      post custom_table_custom_records_path(@table), params: { values: { @email_field.id.to_s => "charlie@example.com" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show custom record" do
    get custom_record_path(@record)
    assert_response :success
  end

  test "should get edit" do
    get edit_custom_record_path(@record)
    assert_response :success
  end

  test "should update custom record" do
    patch custom_record_path(@record), params: { values: { @name_field.id.to_s => "Alice Updated" } }
    assert_redirected_to custom_record_path(@record)
    assert_equal "Alice Updated", @record.custom_values.find_by(custom_field: @name_field).reload.value
  end

  test "should not update custom record with missing required fields" do
    patch custom_record_path(@record), params: { values: { @name_field.id.to_s => "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy custom record" do
    assert_difference "CustomRecord.count", -1 do
      delete custom_record_path(@record)
    end

    assert_redirected_to custom_table_path(@table)
  end

  test "should redirect when not managing" do
    stop_managing_organisation
    get edit_custom_record_path(@record)
    assert_redirected_to organisations_path
  end
end
