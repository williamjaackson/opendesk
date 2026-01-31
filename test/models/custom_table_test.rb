require "test_helper"

class CustomTableTest < ActiveSupport::TestCase
  test "valid table" do
    table = custom_tables(:contacts)
    assert table.valid?
  end

  test "name must be plural" do
    table = CustomTable.new(name: "Contact", organisation: organisations(:one))
    assert_not table.valid?
    assert_includes table.errors[:name].join, "must be plural"
  end

  test "plural name is valid" do
    table = CustomTable.new(name: "Contacts", organisation: organisations(:one))
    assert table.valid?
  end
end
