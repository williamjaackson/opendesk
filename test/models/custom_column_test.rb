require "test_helper"

class CustomColumnTest < ActiveSupport::TestCase
  test "effective_options returns manual options when no linked column" do
    column = custom_columns(:select)
    assert_equal [ "Active", "Inactive", "Pending" ], column.effective_options
  end

  test "effective_options returns linked column values sorted" do
    column = custom_columns(:linked_select)
    assert_equal [ "Deal Alpha", "Deal Beta" ], column.effective_options
  end

  test "effective_options returns empty array when linked column has no values" do
    deal_name = custom_columns(:deal_name)
    deal_name.custom_values.destroy_all

    column = custom_columns(:linked_select)
    assert_equal [], column.effective_options
  end

  test "select_source returns manual for regular select" do
    assert_equal "manual", custom_columns(:select).select_source
  end

  test "select_source returns linked for linked select" do
    assert_equal "linked", custom_columns(:linked_select).select_source
  end

  test "select_source writer overrides inferred value" do
    column = custom_columns(:select)
    column.select_source = "linked"
    assert_equal "linked", column.select_source
  end

  test "linked_table_id returns the linked column's table id" do
    column = custom_columns(:linked_select)
    assert_equal custom_tables(:deals).id, column.linked_table_id
  end

  test "linked_table_id returns nil for manual select" do
    assert_nil custom_columns(:select).linked_table_id
  end

  test "clears options when select_source is linked" do
    column = custom_columns(:select)
    column.select_source = "linked"
    column.linked_column_id = custom_columns(:deal_name).id
    column.valid?
    assert_nil column.options
  end

  test "clears linked_column_id when select_source is manual" do
    column = custom_columns(:linked_select)
    column.select_source = "manual"
    column.options_text = "A\nB"
    column.valid?
    assert_nil column.linked_column_id
  end

  test "validates linked column belongs to same organisation" do
    column = custom_columns(:select)
    column.select_source = "linked"
    column.linked_column_id = custom_columns(:deal_name).id
    assert column.valid?
  end

  test "validates linked_column_id must be selected when source is linked" do
    column = custom_columns(:select)
    column.select_source = "linked"
    column.linked_column_id = nil
    assert_not column.valid?
    assert_includes column.errors[:linked_column_id], "must be selected"
  end

  test "validates options_text must have at least one option when manual" do
    column = custom_columns(:select)
    column.select_source = "manual"
    column.options_text = ""
    assert_not column.valid?
    assert_includes column.errors[:options_text], "must have at least one option"
  end

  test "valid regex pattern is accepted" do
    column = custom_columns(:name)
    column.regex_pattern = '^\d{3}-\d{4}$'
    column.regex_label = "Phone Number"
    assert column.valid?
  end

  test "invalid regex pattern is rejected" do
    column = custom_columns(:name)
    column.regex_pattern = "[invalid"
    column.regex_label = "Test"
    assert_not column.valid?
    assert_includes column.errors[:regex_pattern], "is not a valid regular expression"
  end

  test "regex pattern requires label" do
    column = custom_columns(:name)
    column.regex_pattern = '^\d+$'
    column.regex_label = ""
    assert_not column.valid?
    assert_includes column.errors[:regex_label], "can't be blank"
  end

  test "regex label requires pattern" do
    column = custom_columns(:name)
    column.regex_pattern = ""
    column.regex_label = "Phone Number"
    assert_not column.valid?
    assert_includes column.errors[:regex_pattern], "can't be blank"
  end

  test "regex pattern cleared when column_type is not text or number" do
    column = custom_columns(:email)
    column.regex_pattern = '^\d+$'
    column.regex_label = "Test"
    column.valid?
    assert_nil column.regex_pattern
    assert_nil column.regex_label
  end

  test "computed column requires formula" do
    column = custom_tables(:contacts).custom_columns.new(name: "Full Name", column_type: "computed")
    assert_not column.valid?
    assert_includes column.errors[:formula], "can't be blank"
  end

  test "computed column is valid with formula" do
    column = custom_tables(:contacts).custom_columns.new(name: "Full Name", column_type: "computed", formula: "{First} {Last}")
    assert column.valid?
  end

  test "non-computed column rejects formula" do
    column = custom_columns(:name)
    column.formula = "{Something}"
    assert_not column.valid?
    assert_includes column.errors[:formula], "is only allowed on computed columns"
  end

  test "computed column forces required to false" do
    column = custom_tables(:contacts).custom_columns.new(name: "Full Name", column_type: "computed", formula: "{A}", required: true)
    column.valid?
    assert_equal false, column.required
  end

  test "computed column clears regex" do
    column = custom_tables(:contacts).custom_columns.new(name: "Test", column_type: "computed", formula: "{A}", regex_pattern: "\\d+", regex_label: "Test")
    column.valid?
    assert_nil column.regex_pattern
    assert_nil column.regex_label
  end

  test "computed column clears options and linked_column_id" do
    column = custom_tables(:contacts).custom_columns.new(name: "Test", column_type: "computed", formula: "{A}", options: [ "A" ], linked_column_id: custom_columns(:deal_name).id)
    column.valid?
    assert_nil column.options
    assert_nil column.linked_column_id
  end

  test "computed? returns true for computed columns" do
    column = CustomColumn.new(column_type: "computed")
    assert column.computed?
  end

  test "computed? returns false for non-computed columns" do
    column = CustomColumn.new(column_type: "text")
    assert_not column.computed?
  end
end
