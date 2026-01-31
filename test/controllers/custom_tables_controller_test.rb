require "test_helper"

class CustomTablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
  end

  test "should get new" do
    get new_custom_table_path
    assert_response :success
  end

  test "should create custom table and redirect to edit" do
    assert_difference "CustomTable.count", 1 do
      post custom_tables_path, params: { custom_table: { name: "Projects" } }
    end

    table = CustomTable.last
    assert_equal "Projects", table.name
    assert_equal organisations(:one), table.organisation
    assert_redirected_to edit_custom_table_path(table)
  end

  test "should not create custom table with blank name" do
    assert_no_difference "CustomTable.count" do
      post custom_tables_path, params: { custom_table: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show custom table" do
    get custom_table_path(custom_tables(:contacts))
    assert_response :success
  end

  test "should get edit" do
    get edit_custom_table_path(custom_tables(:contacts))
    assert_response :success
  end

  test "should update custom table" do
    table = custom_tables(:contacts)
    patch custom_table_path(table), params: { custom_table: { name: "People" } }
    assert_redirected_to custom_table_path(table)
    assert_equal "People", table.reload.name
  end

  test "should destroy custom table and redirect to dashboard" do
    table = custom_tables(:contacts)
    assert_difference "CustomTable.count", -1 do
      delete custom_table_path(table)
    end

    assert_redirected_to dashboard_path
  end

  test "should reorder custom tables" do
    contacts = custom_tables(:contacts)
    deals = custom_tables(:deals)
    projects = custom_tables(:projects)

    patch reorder_custom_tables_path, params: { ids: [ projects.id, contacts.id, deals.id ] }, as: :json
    assert_response :no_content

    assert_equal 0, projects.reload.position
    assert_equal 1, contacts.reload.position
    assert_equal 2, deals.reload.position
  end

  test "should assign position on create" do
    post custom_tables_path, params: { custom_table: { name: "Tickets" } }
    table = CustomTable.last
    assert_equal 3, table.position
  end

  test "should redirect to organisations when not managing" do
    stop_managing_organisation
    get edit_custom_table_path(custom_tables(:contacts))
    assert_redirected_to organisations_path
  end
end
