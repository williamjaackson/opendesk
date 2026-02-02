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

    assert_equal 11, CustomColumn.last.position
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

  test "should create column with fixed backfill" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Notes", column_type: "text", backfill_mode: "fixed", backfill_value: "N/A" }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    assert_equal 3, column.custom_values.count
    assert column.custom_values.all? { |v| v.value == "N/A" }
  end

  test "should create column with copy from column backfill" do
    name_column = custom_columns(:name)
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Name Copy", column_type: "text", backfill_mode: "column", backfill_column_id: name_column.id }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    assert_equal 2, column.custom_values.count
    assert_equal "Alice Smith", column.custom_values.find_by(custom_record: custom_records(:alice)).value
    assert_equal "Bob Jones", column.custom_values.find_by(custom_record: custom_records(:bob)).value
  end

  test "should create column without backfill when checkbox unchecked" do
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Notes", column_type: "text" }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    assert_equal 0, column.custom_values.count
  end

  test "should reject fixed backfill with invalid value for column type" do
    assert_no_difference "CustomColumn.count" do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Count", column_type: "number", backfill_mode: "fixed", backfill_value: "abc" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should reject fixed backfill with blank value" do
    assert_no_difference "CustomColumn.count" do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Notes", column_type: "text", backfill_mode: "fixed", backfill_value: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should reject column backfill without selected column" do
    assert_no_difference "CustomColumn.count" do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Notes", column_type: "text", backfill_mode: "column", backfill_column_id: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should skip invalid values when copying from column without fallback" do
    name_column = custom_columns(:name)
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Contact Number", column_type: "number", backfill_mode: "column", backfill_column_id: name_column.id }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    assert_equal 0, column.custom_values.count
  end

  test "should use fallback for incompatible values when copying from column" do
    name_column = custom_columns(:name)
    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Contact Number", column_type: "number", backfill_mode: "column", backfill_column_id: name_column.id, backfill_fallback: "0" }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    assert_equal 3, column.custom_values.count
    assert column.custom_values.all? { |v| v.value == "0" }
  end

  test "should use source value when compatible and fallback when not" do
    number_column = custom_columns(:number)
    custom_records(:alice).custom_values.create!(custom_column: number_column, value: "42")

    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Number Copy", column_type: "number", backfill_mode: "column", backfill_column_id: number_column.id, backfill_fallback: "0" }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    assert_equal 3, column.custom_values.count
    assert_equal "42", column.custom_values.find_by(custom_record: custom_records(:alice)).value
    assert_equal "0", column.custom_values.find_by(custom_record: custom_records(:bob)).value
    assert_equal "0", column.custom_values.find_by(custom_record: custom_records(:charlie)).value
  end

  test "should reject column backfill with invalid fallback value" do
    name_column = custom_columns(:name)
    assert_no_difference "CustomColumn.count" do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Contact Number", column_type: "number", backfill_mode: "column", backfill_column_id: name_column.id, backfill_fallback: "abc" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should coerce datetime to date when backfilling from column" do
    datetime_column = custom_columns(:datetime)
    custom_records(:alice).custom_values.create!(custom_column: datetime_column, value: "2025-06-15T14:30")
    custom_records(:bob).custom_values.create!(custom_column: datetime_column, value: "2025-01-01T09:00")

    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Date Only", column_type: "date", backfill_mode: "column", backfill_column_id: datetime_column.id }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    assert_equal "2025-06-15", column.custom_values.find_by(custom_record: custom_records(:alice)).value
    assert_equal "2025-01-01", column.custom_values.find_by(custom_record: custom_records(:bob)).value
  end

  test "should coerce datetime to time when backfilling from column" do
    datetime_column = custom_columns(:datetime)
    custom_records(:alice).custom_values.create!(custom_column: datetime_column, value: "2025-06-15T14:30")

    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Time Only", column_type: "time", backfill_mode: "column", backfill_column_id: datetime_column.id }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    assert_equal "14:30", column.custom_values.find_by(custom_record: custom_records(:alice)).value
  end

  test "should coerce date to datetime when backfilling from column" do
    date_column = custom_columns(:date)
    custom_records(:alice).custom_values.create!(custom_column: date_column, value: "2025-06-15")

    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Full Datetime", column_type: "datetime", backfill_mode: "column", backfill_column_id: date_column.id }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    assert_equal "2025-06-15T00:00", column.custom_values.find_by(custom_record: custom_records(:alice)).value
  end

  test "should coerce time to datetime when backfilling from column" do
    time_column = custom_columns(:time)
    custom_records(:alice).custom_values.create!(custom_column: time_column, value: "14:30")

    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Full Datetime", column_type: "datetime", backfill_mode: "column", backfill_column_id: time_column.id }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    expected = "1970-01-01T14:30"
    assert_equal expected, column.custom_values.find_by(custom_record: custom_records(:alice)).value
  end

  test "should coerce text containing datetime to date when backfilling" do
    name_column = custom_columns(:name)
    custom_records(:charlie).custom_values.create!(custom_column: name_column, value: "2025-06-15T14:30")

    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Date From Text", column_type: "date", backfill_mode: "column", backfill_column_id: name_column.id }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    # charlie's datetime text is coerced to date
    assert_equal "2025-06-15", column.custom_values.find_by(custom_record: custom_records(:charlie)).value
    # alice ("Alice Smith") and bob ("Bob Jones") are not datetime-formatted, so they're skipped
    assert_nil column.custom_values.find_by(custom_record: custom_records(:alice))
    assert_nil column.custom_values.find_by(custom_record: custom_records(:bob))
  end

  test "should coerce text containing time to datetime when backfilling" do
    name_column = custom_columns(:name)
    custom_records(:charlie).custom_values.create!(custom_column: name_column, value: "14:30")

    assert_difference "CustomColumn.count", 1 do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Datetime From Text", column_type: "datetime", backfill_mode: "column", backfill_column_id: name_column.id }
      }
    end

    column = CustomColumn.last
    assert_redirected_to edit_table_path(@custom_table)
    expected = "1970-01-01T14:30"
    assert_equal expected, column.custom_values.find_by(custom_record: custom_records(:charlie)).value
  end

  test "should get backfill select options" do
    get backfill_select_options_table_columns_path(@custom_table), params: {
      options_text: "Alpha\nBravo\nCharlie",
      field_name: "custom_column[backfill_value]",
      field_id: "backfill_value_select",
      frame_id: "backfill_value_select_frame"
    }

    assert_response :success
  end

  test "should reject fixed backfill value that fails regex validation" do
    assert_no_difference "CustomColumn.count" do
      post table_columns_path(@custom_table), params: {
        custom_column: { name: "Phone", column_type: "text", regex_pattern: '^\d{3}-\d{4}$', regex_label: "Phone Number", backfill_mode: "fixed", backfill_value: "not-a-phone" }
      }
    end

    assert_response :unprocessable_entity
  end
end
