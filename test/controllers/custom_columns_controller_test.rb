require "test_helper"

class CustomColumnsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    enable_edit_mode
    @custom_table = custom_tables(:contacts)
  end

  test "should get new" do
    get new_table_column_path(@custom_table)
    assert_response :success
  end

  test "should create custom column" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Phone", column_type: "text", required: false }
      }
    end

    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should create email column" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Work Email", column_type: "email", required: false }
      }
    end

    assert_equal "email", CustomColumn.last.column_type
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should create number column" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Age", column_type: "number", required: false }
      }
    end

    assert_equal "number", CustomColumn.last.column_type
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should create boolean column" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Active", column_type: "boolean", required: false }
      }
    end

    assert_equal "boolean", CustomColumn.last.column_type
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should create time column" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Check-in", column_type: "time", required: false }
      }
    end

    assert_equal "time", CustomColumn.last.column_type
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should not create column without type" do
    assert_no_difference "CustomColumn.count" do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Phone" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should create date column" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Birthday", column_type: "date", required: false }
      }
    end

    assert_equal "date", CustomColumn.last.column_type
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should not create column with invalid type" do
    assert_no_difference "CustomColumn.count" do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Phone", column_type: "invalid" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_table_column_path(@custom_table, custom_columns(:name))
    assert_response :success
  end

  test "should update custom column name" do
    column = custom_columns(:name)
    patch table_column_path(@custom_table, column), params: { custom_column: { name: "Full name" } }

    assert_redirected_to edit_table_path(@custom_table)
    assert_equal "Full name", column.reload.name
  end

  test "should not change column type on update" do
    column = custom_columns(:name)
    patch table_column_path(@custom_table, column), params: { custom_column: { name: "Full name", column_type: "number" } }

    assert_equal "text", column.reload.column_type
  end

  test "should destroy custom column" do
    column = custom_columns(:email)

    assert_difference "CustomColumn.count", -1 do
      delete table_column_path(@custom_table, column)
    end

    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should reorder custom columns" do
    name_column = custom_columns(:name)
    email_column = custom_columns(:email)

    patch reorder_table_columns_path(@custom_table),
      params: { ids: [ email_column.id, name_column.id ] }, as: :json
    assert_response :no_content

    assert_equal 0, email_column.reload.position
    assert_equal 1, name_column.reload.position
  end

  test "should create datetime column" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Appointment", column_type: "datetime", required: false }
      }
    end

    assert_equal "datetime", CustomColumn.last.column_type
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should auto-increment position" do
    post table_columns_path(@custom_table), params: {
      custom_column: { name: "Phone", column_type: "text" }
    }

    assert_equal 8, CustomColumn.last.position
  end

  test "should create select column" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Priority", column_type: "select", options_text: "High\nMedium\nLow" }
      }
    end

    column = CustomColumn.last
    assert_equal "select", column.column_type
    assert_equal ["High", "Medium", "Low"], column.options
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should not create select column without options" do
    assert_no_difference "CustomColumn.count" do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Priority", column_type: "select", options_text: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should update select column options" do
    column = custom_columns(:select)
    patch table_column_path(@custom_table, column), params: {
      custom_column: { options_text: "Open\nClosed" }
    }

    assert_redirected_to edit_table_path(@custom_table)
    assert_equal ["Open", "Closed"], column.reload.options
  end
end
