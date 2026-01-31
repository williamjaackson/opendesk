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

  test "should create custom table" do
    assert_difference "CustomTable.count", 1 do
      post custom_tables_path, params: { custom_table: { name: "Projects" } }
    end

    assert_redirected_to custom_table_path(CustomTable.last)
  end

  test "should show custom table" do
    get custom_table_path(custom_tables(:contacts))
    assert_response :success
  end

  test "should redirect to organisations when not managing" do
    stop_managing_organisation
    get new_custom_table_path
    assert_redirected_to organisations_path
  end
end
