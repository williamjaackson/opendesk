require "test_helper"

class CustomRelationshipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    enable_builder_mode
    @custom_table = custom_tables(:contacts)
    @relationship = custom_relationships(:contacts_deals)
  end

  test "should get new" do
    get new_table_relationship_path(@custom_table)
    assert_response :success
  end

  test "should create custom relationship" do
    @relationship.destroy

    assert_difference "CustomRelationship.count", 1 do
      post table_relationships_path(@custom_table), params: {
        custom_relationship: {
          name: "Deals",
          inverse_name: "Contact",
          kind: "one_to_many",
          target_table_id: custom_tables(:deals).id
        }
      }
    end

    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should not create relationship with blank name" do
    assert_no_difference "CustomRelationship.count" do
      post table_relationships_path(@custom_table), params: {
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
      post table_relationships_path(@custom_table), params: {
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
    get edit_table_relationship_path(@custom_table, @relationship)
    assert_response :success
  end

  test "should update relationship name and inverse name" do
    patch table_relationship_path(@custom_table, @relationship), params: {
      custom_relationship: { name: "Active Deals", inverse_name: "Primary Contact" }
    }

    assert_redirected_to edit_table_path(@custom_table)
    @relationship.reload
    assert_equal "Active Deals", @relationship.name
    assert_equal "Primary Contact", @relationship.inverse_name
  end

  test "should not change kind on update" do
    patch table_relationship_path(@custom_table, @relationship), params: {
      custom_relationship: { name: "Deals", inverse_name: "Contact", kind: "many_to_many" }
    }

    assert_equal "one_to_many", @relationship.reload.kind
  end

  test "should reorder relationships" do
    deals = custom_relationships(:contacts_deals)
    projects = custom_relationships(:contacts_projects)

    patch reorder_table_relationships_path(@custom_table),
      params: { ids: [ projects.id, deals.id ] }, as: :json
    assert_response :no_content

    assert_equal 0, projects.reload.position
    assert_equal 1, deals.reload.position
  end

  test "should auto-increment position on create" do
    post table_relationships_path(@custom_table), params: {
      custom_relationship: {
        name: "Tasks",
        inverse_name: "Assigned Contact",
        kind: "one_to_many",
        target_table_id: custom_tables(:deals).id
      }
    }

    assert_equal 5, CustomRelationship.last.position
  end

  test "should destroy relationship and its links" do
    assert_difference "CustomRelationship.count", -1 do
      assert_difference "CustomRecordLink.count", -1 do
        delete table_relationship_path(@custom_table, @relationship)
      end
    end

    assert_redirected_to edit_table_path(@custom_table)
  end

  test "should create symmetric many-to-many self-referential" do
    assert_difference "CustomRelationship.count", 1 do
      post table_relationships_path(@custom_table), params: {
        custom_relationship: {
          name: "Friends",
          inverse_name: "Friends",
          kind: "many_to_many",
          target_table_id: @custom_table.id,
          symmetric: "1"
        }
      }
    end

    rel = CustomRelationship.last
    assert rel.symmetric?
    assert_equal "Friends", rel.inverse_name
  end

  test "should auto-set symmetric for one-to-one self-referential" do
    custom_relationships(:contacts_spouse).destroy

    assert_difference "CustomRelationship.count", 1 do
      post table_relationships_path(@custom_table), params: {
        custom_relationship: {
          name: "Partner",
          inverse_name: "anything",
          kind: "one_to_one",
          target_table_id: @custom_table.id
        }
      }
    end

    rel = CustomRelationship.last
    assert rel.symmetric?
    assert_equal "Partner", rel.inverse_name
  end
end
