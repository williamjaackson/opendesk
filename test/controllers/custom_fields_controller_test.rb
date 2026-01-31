require "test_helper"

class CustomFieldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    @custom_table = custom_tables(:contacts)
  end

  test "should get new" do
    get new_table_field_path(@custom_table)
    assert_response :success
  end

  test "should create custom field" do
    assert_difference "CustomField.count", 1 do
      post table_fields_path(@custom_table), params: {
        custom_field: { name: "Phone", field_type: "text", required: false }
      }
    end

    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should get edit" do
    get edit_table_field_path(@custom_table, custom_fields(:name))
    assert_response :success
  end

  test "should update custom field name" do
    field = custom_fields(:name)
    patch table_field_path(@custom_table, field), params: { custom_field: { name: "Full name" } }

    assert_redirected_to edit_table_path(@custom_table)
    assert_equal "Full name", field.reload.name
  end

  test "should not change field type on update" do
    field = custom_fields(:name)
    patch table_field_path(@custom_table, field), params: { custom_field: { name: "Full name", field_type: "number" } }

    assert_equal "text", field.reload.field_type
  end

  test "should destroy custom field" do
    field = custom_fields(:email)

    assert_difference "CustomField.count", -1 do
      delete table_field_path(@custom_table, field)
    end

    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should reorder custom fields" do
    name_field = custom_fields(:name)
    email_field = custom_fields(:email)

    patch reorder_table_fields_path(@custom_table),
      params: { ids: [ email_field.id, name_field.id ] }, as: :json
    assert_response :no_content

    assert_equal 0, email_field.reload.position
    assert_equal 1, name_field.reload.position
  end

  test "should auto-increment position" do
    post table_fields_path(@custom_table), params: {
      custom_field: { name: "Phone", field_type: "text" }
    }

    assert_equal 2, CustomField.last.position
  end
end
