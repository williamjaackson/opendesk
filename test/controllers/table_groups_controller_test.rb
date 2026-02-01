require "test_helper"

class TableGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
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
    assert_redirected_to root_path
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
    assert_redirected_to root_path
    assert_equal "Main", group.reload.name
  end

  test "should destroy table group" do
    group = table_groups(:default)
    assert_difference "TableGroup.count", -1 do
      delete group_path(group)
    end

    assert_redirected_to root_path
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
