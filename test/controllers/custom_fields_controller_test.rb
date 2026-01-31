require "test_helper"

class CustomFieldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    @custom_table = custom_tables(:contacts)
  end

  test "should get new" do
    get new_custom_table_custom_field_path(@custom_table)
    assert_response :success
  end

  test "should create custom field" do
    assert_difference "CustomField.count", 1 do
      post custom_table_custom_fields_path(@custom_table), params: {
        custom_field: { name: "Phone", field_type: "text", required: false }
      }
    end

    assert_redirected_to edit_custom_table_path(@custom_table)
  end

  test "should destroy custom field" do
    field = custom_fields(:email)

    assert_difference "CustomField.count", -1 do
      delete custom_field_path(field)
    end

    assert_redirected_to edit_custom_table_path(@custom_table)
  end

  test "should auto-increment position" do
    post custom_table_custom_fields_path(@custom_table), params: {
      custom_field: { name: "Phone", field_type: "text" }
    }

    assert_equal 2, CustomField.last.position
  end
end
