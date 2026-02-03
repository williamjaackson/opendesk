require "test_helper"

class CustomTablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    enable_builder_mode
  end

  test "should get new" do
    get new_table_path
    assert_response :success
  end

  test "should create custom table and redirect to edit" do
    assert_difference "CustomTable.count", 1 do
      post tables_path, params: { custom_table: { name: "Tickets" } }
    end

    table = CustomTable.last
    assert_equal "Tickets", table.name
    assert_equal organisations(:one), table.organisation
    assert_redirected_to edit_table_path(table)
  end

  test "should not create custom table with blank name" do
    assert_no_difference "CustomTable.count" do
      post tables_path, params: { custom_table: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show custom table" do
    get table_path(custom_tables(:contacts))
    assert_response :success
  end

  test "should get edit" do
    get edit_table_path(custom_tables(:contacts))
    assert_response :success
  end

  test "should update custom table" do
    table = custom_tables(:contacts)
    patch table_path(table), params: { custom_table: { name: "People" } }
    assert_redirected_to table_path(table.reload)
    assert_equal "People", table.name
  end

  test "should destroy custom table and redirect to dashboard" do
    table = custom_tables(:contacts)
    assert_difference "CustomTable.count", -1 do
      delete table_path(table)
    end

    assert_redirected_to root_path
  end

  test "should reorder custom tables" do
    contacts = custom_tables(:contacts)
    deals = custom_tables(:deals)
    projects = custom_tables(:projects)

    patch reorder_tables_path, params: { ids: [ projects.id, contacts.id, deals.id ] }, as: :json
    assert_response :no_content

    assert_equal 0, projects.reload.position
    assert_equal 1, contacts.reload.position
    assert_equal 2, deals.reload.position
  end

  test "should assign position on create" do
    post tables_path, params: { custom_table: { name: "Tickets" } }
    table = CustomTable.last
    assert_equal 3, table.position
  end

  test "should default to first table group on create" do
    post tables_path, params: { custom_table: { name: "Tickets" } }
    table = CustomTable.last
    assert_equal table_groups(:default), table.table_group
  end

  test "should accept table_group_id on create" do
    group = Current.organisation.table_groups.create!(name: "Sales", slug: "sales", position: 1)
    post tables_path, params: { custom_table: { name: "Tickets", table_group_id: group.id } }
    table = CustomTable.last
    assert_equal group, table.table_group
  end

  test "should redirect to organisations when not managing" do
    stop_managing_organisation
    get edit_table_path(custom_tables(:contacts))
    assert_redirected_to organisations_path
  end
end
