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
    table = CustomTable.new(name: "Invoices", organisation: organisations(:one))
    assert table.valid?
  end

  test "slug is auto-generated from name" do
    table = CustomTable.new(name: "Hot Leads", organisation: organisations(:one))
    table.valid?
    assert_equal "hot-leads", table.slug
  end

  test "to_param returns slug" do
    table = custom_tables(:contacts)
    assert_equal "contacts", table.to_param
  end

  test "slug updates when name changes" do
    table = custom_tables(:contacts)
    table.name = "People"
    table.valid?
    assert_equal "people", table.slug
  end

  test "name must be unique per organisation" do
    table = CustomTable.new(name: "Contacts", organisation: organisations(:one))
    assert_not table.valid?
    assert_includes table.errors[:name], "has already been taken"
  end

  test "slug must be unique per organisation" do
    table = CustomTable.new(name: "Contacts", organisation: organisations(:one))
    assert_not table.valid?
    assert_includes table.errors[:slug], "has already been taken"
  end

  test "reserved slugs are rejected" do
    CustomTable::RESERVED_SLUGS.each do |reserved|
      table = CustomTable.new(organisation: organisations(:one))
      table.slug = reserved
      table.valid?
      assert_includes table.errors[:slug], "is reserved", "Expected '#{reserved}' to be reserved"
    end
  end
end
