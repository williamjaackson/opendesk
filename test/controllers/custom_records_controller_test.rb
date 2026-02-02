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

  test "should show both directions of asymmetric self-referential relationship" do
    get table_record_path(@table, @record)
    assert_response :success
    assert_select "h2", text: "Children"
    assert_select "h2", text: "Parent"
  end

  test "should show one section for symmetric relationship" do
    get table_record_path(@table, @record)
    assert_response :success
    assert_select "h2", text: "Spouse", count: 1
    assert_select "h2", text: "Knows", count: 1
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

  test "should create record with boolean value" do
    boolean_column = custom_columns(:boolean)
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", boolean_column.id.to_s => "1" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should create record with boolean value unchecked" do
    boolean_column = custom_columns(:boolean)
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", boolean_column.id.to_s => "0" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should update record with boolean value" do
    boolean_column = custom_columns(:boolean)
    post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", boolean_column.id.to_s => "1" } }
    record = CustomRecord.last

    patch table_record_path(@table, record), params: { values: { @name_column.id.to_s => "Charlie", boolean_column.id.to_s => "0" } }
    assert_redirected_to table_record_path(@table, record)
    assert_equal "0", record.custom_values.find_by(custom_column: boolean_column).reload.value
  end

  test "should not create record with invalid boolean value" do
    boolean_column = custom_columns(:boolean)
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", boolean_column.id.to_s => "abc" } }
    end

    assert_response :unprocessable_entity
  end

  test "should create record with valid date value" do
    date_column = custom_columns(:date)
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", date_column.id.to_s => "2026-01-15" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should not create record with invalid date value" do
    date_column = custom_columns(:date)
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", date_column.id.to_s => "not-a-date" } }
    end

    assert_response :unprocessable_entity
  end

  test "should update record with valid date value" do
    date_column = custom_columns(:date)
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice", date_column.id.to_s => "2026-06-20" } }

    assert_redirected_to table_record_path(@table, @record)
    assert_equal "2026-06-20", @record.custom_values.find_by(custom_column: date_column).reload.value
  end

  test "should not update record with invalid date value" do
    date_column = custom_columns(:date)
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice", date_column.id.to_s => "bad-date" } }

    assert_response :unprocessable_entity
  end

  test "should create record with valid time value" do
    time_column = custom_columns(:time)
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", time_column.id.to_s => "14:30" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should not create record with invalid time value" do
    time_column = custom_columns(:time)
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", time_column.id.to_s => "25:00" } }
    end

    assert_response :unprocessable_entity
  end

  test "should update record with valid time value" do
    time_column = custom_columns(:time)
    post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", time_column.id.to_s => "09:00" } }
    record = CustomRecord.last

    patch table_record_path(@table, record), params: { values: { @name_column.id.to_s => "Charlie", time_column.id.to_s => "17:45" } }
    assert_redirected_to table_record_path(@table, record)
    assert_equal "17:45", record.custom_values.find_by(custom_column: time_column).reload.value
  end

  test "should not update record with invalid time value" do
    time_column = custom_columns(:time)
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice", time_column.id.to_s => "not-a-time" } }

    assert_response :unprocessable_entity
  end

  test "should create record with valid datetime value" do
    datetime_column = custom_columns(:datetime)
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", datetime_column.id.to_s => "2026-01-15T14:30" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should not create record with invalid datetime value" do
    datetime_column = custom_columns(:datetime)
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", datetime_column.id.to_s => "not-a-datetime" } }
    end

    assert_response :unprocessable_entity
  end

  test "should update record with valid datetime value" do
    datetime_column = custom_columns(:datetime)
    post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", datetime_column.id.to_s => "2026-01-15T09:00" } }
    record = CustomRecord.last

    patch table_record_path(@table, record), params: { values: { @name_column.id.to_s => "Charlie", datetime_column.id.to_s => "2026-06-20T17:45" } }
    assert_redirected_to table_record_path(@table, record)
    assert_equal "2026-06-20T17:45", record.custom_values.find_by(custom_column: datetime_column).reload.value
  end

  test "should not update record with invalid datetime value" do
    datetime_column = custom_columns(:datetime)
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice", datetime_column.id.to_s => "bad-datetime" } }

    assert_response :unprocessable_entity
  end

  test "should create record with valid select value" do
    select_column = custom_columns(:select)
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", select_column.id.to_s => "Active" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should not create record with invalid select value" do
    select_column = custom_columns(:select)
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", select_column.id.to_s => "InvalidOption" } }
    end

    assert_response :unprocessable_entity
  end

  test "should update record with valid select value" do
    select_column = custom_columns(:select)
    post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", select_column.id.to_s => "Active" } }
    record = CustomRecord.last

    patch table_record_path(@table, record), params: { values: { @name_column.id.to_s => "Charlie", select_column.id.to_s => "Inactive" } }
    assert_redirected_to table_record_path(@table, record)
    assert_equal "Inactive", record.custom_values.find_by(custom_column: select_column).reload.value
  end

  test "should not update record with invalid select value" do
    select_column = custom_columns(:select)
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice", select_column.id.to_s => "BadValue" } }

    assert_response :unprocessable_entity
  end

  test "should create record with valid linked select value" do
    linked_select = custom_columns(:linked_select)
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", linked_select.id.to_s => "Deal Alpha" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should not create record with invalid linked select value" do
    linked_select = custom_columns(:linked_select)
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", linked_select.id.to_s => "Nonexistent Deal" } }
    end

    assert_response :unprocessable_entity
  end

  test "should update record with valid linked select value" do
    linked_select = custom_columns(:linked_select)
    post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", linked_select.id.to_s => "Deal Alpha" } }
    record = CustomRecord.last

    patch table_record_path(@table, record), params: { values: { @name_column.id.to_s => "Charlie", linked_select.id.to_s => "Deal Beta" } }
    assert_redirected_to table_record_path(@table, record)
    assert_equal "Deal Beta", record.custom_values.find_by(custom_column: linked_select).reload.value
  end

  test "should not update record with invalid linked select value" do
    linked_select = custom_columns(:linked_select)
    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice", linked_select.id.to_s => "BadDeal" } }

    assert_response :unprocessable_entity
  end

  test "should redirect when not managing" do
    stop_managing_organisation
    get edit_table_record_path(@table, @record)
    assert_redirected_to organisations_path
  end

  test "should create record with value matching regex" do
    regex_column = custom_columns(:regex_text)
    assert_difference "CustomRecord.count", 1 do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", regex_column.id.to_s => "123-4567" } }
    end

    assert_redirected_to table_path(@table)
  end

  test "should not create record with value not matching regex" do
    regex_column = custom_columns(:regex_text)
    assert_no_difference "CustomRecord.count" do
      post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", regex_column.id.to_s => "bad-value" } }
    end

    assert_response :unprocessable_entity
  end

  test "should evaluate computed columns on create" do
    computed = @table.custom_columns.create!(name: "Full Name", column_type: "computed", formula: "{Name}", position: 99)
    post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie" } }

    record = CustomRecord.last
    assert_equal "Charlie", record.custom_values.find_by(custom_column: computed)&.value
  end

  test "should evaluate computed columns on update" do
    computed = @table.custom_columns.create!(name: "Full Name", column_type: "computed", formula: "{Name}", position: 99)
    FormulaEvaluator.evaluate_record(@record, [ computed ])

    patch table_record_path(@table, @record), params: { values: { @name_column.id.to_s => "Alice Updated" } }
    assert_equal "Alice Updated", @record.custom_values.reload.find_by(custom_column: computed)&.value
  end

  test "should evaluate formula mode computed column" do
    boolean_column = custom_columns(:boolean)
    computed = @table.custom_columns.create!(name: "Status", column_type: "computed", formula: '=IF({Active}, UPPER({Name}), "Inactive")', position: 99)

    post table_records_path(@table), params: { values: { @name_column.id.to_s => "Charlie", boolean_column.id.to_s => "1" } }

    record = CustomRecord.last
    assert_equal "CHARLIE", record.custom_values.find_by(custom_column: computed)&.value
  end
end
