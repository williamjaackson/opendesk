require "test_helper"

class TableGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    enable_edit_mode
  end

  test "should get index" do
    get groups_path
    assert_response :success
  end

  test "should redirect show to first table" do
    get group_path(table_groups(:default))
    assert_redirected_to table_path(custom_tables(:contacts))
  end

  test "should render create table page for empty group" do
    empty_group = Current.organisation.table_groups.create!(name: "Empty", slug: "empty", position: 1)
    get group_path(empty_group)
    assert_response :success
    assert_select "h1", "Create your first table"
  end

  test "should get new" do
    get new_group_path
    assert_response :success
  end

  test "should create table group" do
    assert_difference "TableGroup.count", 1 do
      post groups_path, params: { table_group: { name: "Sales" } }
    end

    group = TableGroup.last
    assert_equal "Sales", group.name
    assert_equal "sales", group.slug
    assert_equal organisations(:one), group.organisation
    assert_redirected_to groups_path
  end

  test "should not create table group with blank name" do
    assert_no_difference "TableGroup.count" do
      post groups_path, params: { table_group: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_group_path(table_groups(:default))
    assert_response :success
  end

  test "should update table group" do
    group = table_groups(:default)
    patch group_path(group), params: { table_group: { name: "Main" } }
    assert_redirected_to groups_path
    assert_equal "Main", group.reload.name
  end

  test "should destroy empty table group" do
    empty_group = Current.organisation.table_groups.create!(name: "Empty", slug: "empty", position: 1)

    assert_difference "TableGroup.count", -1 do
      delete group_path(empty_group)
    end

    assert_redirected_to groups_path
  end

  test "should not destroy table group with tables" do
    group = table_groups(:default)
    Current.organisation.table_groups.create!(name: "Other", slug: "other", position: 1)

    assert_no_difference "TableGroup.count" do
      delete group_path(group)
    end

    assert_redirected_to groups_path
    assert_equal "Cannot delete a group that contains tables", flash[:alert]
  end

  test "should not destroy last table group" do
    CustomTable.where(table_group: table_groups(:default)).update_all(table_group_id: nil)

    assert_no_difference "TableGroup.count" do
      delete group_path(table_groups(:default))
    end

    assert_redirected_to groups_path
    assert_equal "Cannot delete the last group", flash[:alert]
  end

  test "should add table to group" do
    target_group = Current.organisation.table_groups.create!(name: "Sales", slug: "sales", position: 1)
    table = custom_tables(:contacts)

    patch add_table_group_path(target_group), params: { table_id: table.id }, as: :json
    assert_response :no_content

    assert_equal target_group, table.reload.table_group
  end

  test "should reorder table groups" do
    group2 = Current.organisation.table_groups.create!(name: "Sales", slug: "sales", position: 1)
    group1 = table_groups(:default)

    patch reorder_groups_path, params: { ids: [ group2.id, group1.id ] }, as: :json
    assert_response :no_content

    assert_equal 0, group2.reload.position
    assert_equal 1, group1.reload.position
  end

  test "should redirect to organisations when not managing" do
    stop_managing_organisation
    get new_group_path
    assert_redirected_to organisations_path
  end
end
