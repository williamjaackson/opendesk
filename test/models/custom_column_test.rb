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
end
