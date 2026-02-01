require "test_helper"

class TableGroupTest < ActiveSupport::TestCase
  test "valid group" do
    group = table_groups(:default)
    assert group.valid?
  end

  test "name must be present" do
    group = TableGroup.new(organisation: organisations(:one))
    assert_not group.valid?
    assert_includes group.errors[:name], "can't be blank"
  end

  test "name must be unique per organisation" do
    group = TableGroup.new(name: "Tables", organisation: organisations(:one))
    assert_not group.valid?
    assert_includes group.errors[:name], "has already been taken"
  end

  test "slug is auto-generated from name" do
    group = TableGroup.new(name: "Hot Leads", organisation: organisations(:one))
    group.valid?
    assert_equal "hot-leads", group.slug
  end

  test "to_param returns slug" do
    group = table_groups(:default)
    assert_equal "tables", group.to_param
  end

  test "same name allowed in different organisations" do
    group = TableGroup.new(name: "Tables", organisation: organisations(:two))
    assert group.valid?
  end
end
