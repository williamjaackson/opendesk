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

    assert_equal 10, CustomColumn.last.position
  end

  test "should create select column" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Priority", column_type: "select", select_source: "manual", options_text: "High\nMedium\nLow" }
      }
    end

    column = CustomColumn.last
    assert_equal "select", column.column_type
    assert_equal [ "High", "Medium", "Low" ], column.options
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should not create select column without options" do
    assert_no_difference "CustomColumn.count" do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Priority", column_type: "select", select_source: "manual", options_text: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should update select column options" do
    column = custom_columns(:select)
    patch table_column_path(@custom_table, column), params: {
      custom_column: { select_source: "manual", options_text: "Open\nClosed" }
    }

    assert_redirected_to edit_table_path(@custom_table)
    assert_equal [ "Open", "Closed" ], column.reload.options
  end

  test "should update manual select column with linked_column_id empty" do
    column = custom_columns(:select)
    patch table_column_path(@custom_table, column), params: {
      custom_column: { name: "Status Updated", select_source: "manual", options_text: "Active\nInactive\nPending", linked_column_id: "" }
    }

    assert_redirected_to edit_table_path(@custom_table)
    column.reload
    assert_equal "Status Updated", column.name
    assert_nil column.linked_column_id
    assert_equal [ "Active", "Inactive", "Pending" ], column.options
  end

  test "should create linked select column" do
    deal_name = custom_columns(:deal_name)
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Deal Link", column_type: "select", select_source: "linked", linked_column_id: deal_name.id }
      }
    end

    column = CustomColumn.last
    assert_equal "select", column.column_type
    assert_equal deal_name.id, column.linked_column_id
    assert_nil column.options
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should update column to use linked column" do
    column = custom_columns(:select)
    deal_name = custom_columns(:deal_name)
    patch table_column_path(@custom_table, column), params: {
      custom_column: { select_source: "linked", linked_column_id: deal_name.id }
    }

    assert_redirected_to edit_table_path(@custom_table)
    column.reload
    assert_equal deal_name.id, column.linked_column_id
    assert_nil column.options
  end

  test "should switch linked column back to manual" do
    column = custom_columns(:linked_select)
    patch table_column_path(@custom_table, column), params: {
      custom_column: { select_source: "manual", options_text: "X\nY\nZ", linked_column_id: "" }
    }

    assert_redirected_to edit_table_path(@custom_table)
    column.reload
    assert_nil column.linked_column_id
    assert_equal [ "X", "Y", "Z" ], column.options
  end

  test "should create text column with regex_pattern and regex_label" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Phone", column_type: "text", regex_pattern: '^\d{3}-\d{4}$', regex_label: "Phone Number" }
      }
    end

    column = CustomColumn.last
    assert_equal '^\d{3}-\d{4}$', column.regex_pattern
    assert_equal "Phone Number", column.regex_label
    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should update column to add regex" do
    column = custom_columns(:name)
    patch table_column_path(@custom_table, column), params: {
      custom_column: { regex_pattern: '^\w+$', regex_label: "Word Only" }
    }

    assert_redirected_to edit_table_path(@custom_table)
    column.reload
    assert_equal '^\w+$', column.regex_pattern
    assert_equal "Word Only", column.regex_label
  end

  test "should update column to remove regex" do
    column = custom_columns(:regex_text)
    patch table_column_path(@custom_table, column), params: {
      custom_column: { regex_pattern: "", regex_label: "" }
    }

    assert_redirected_to edit_table_path(@custom_table)
    column.reload
    assert_nil column.regex_pattern.presence
    assert_nil column.regex_label.presence
  end
end
