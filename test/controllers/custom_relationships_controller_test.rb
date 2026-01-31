require "test_helper"

class CustomRelationshipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    @custom_table = custom_tables(:contacts)
    @relationship = custom_relationships(:contacts_deals)
  end

  test "should get new" do
    get new_custom_table_custom_relationship_path(@custom_table)
    assert_response :success
  end

  test "should create custom relationship" do
    @relationship.destroy

    assert_difference "CustomRelationship.count", 1 do
      post custom_table_custom_relationships_path(@custom_table), params: {
        custom_relationship: {
          name: "Deals",
          inverse_name: "Contact",
          kind: "one_to_many",
          target_table_id: custom_tables(:deals).id
        }
      }
    end

    assert_redirected_to edit_custom_table_path(@custom_table)
  end

  test "should not create relationship with blank name" do
    assert_no_difference "CustomRelationship.count" do
      post custom_table_custom_relationships_path(@custom_table), params: {
        custom_relationship: {
          name: "",
          inverse_name: "Contact",
          kind: "one_to_many",
          target_table_id: custom_tables(:deals).id
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create relationship with invalid kind" do
    assert_no_difference "CustomRelationship.count" do
      post custom_table_custom_relationships_path(@custom_table), params: {
        custom_relationship: {
          name: "Projects",
          inverse_name: "Contact",
          kind: "invalid",
          target_table_id: custom_tables(:deals).id
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_custom_relationship_path(@relationship)
    assert_response :success
  end

  test "should update relationship name and inverse name" do
    patch custom_relationship_path(@relationship), params: {
      custom_relationship: { name: "Active Deals", inverse_name: "Primary Contact" }
    }

    assert_redirected_to edit_custom_table_path(@custom_table)
    @relationship.reload
    assert_equal "Active Deals", @relationship.name
    assert_equal "Primary Contact", @relationship.inverse_name
  end

  test "should not change kind on update" do
    patch custom_relationship_path(@relationship), params: {
      custom_relationship: { name: "Deals", inverse_name: "Contact", kind: "many_to_many" }
    }

    assert_equal "one_to_many", @relationship.reload.kind
  end

  test "should destroy relationship and its links" do
    assert_difference "CustomRelationship.count", -1 do
      assert_difference "CustomRecordLink.count", -1 do
        delete custom_relationship_path(@relationship)
      end
    end

    assert_redirected_to edit_custom_table_path(@custom_table)
  end
end
