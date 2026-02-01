require "test_helper"

class CustomRecordLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    manage_organisation organisations(:one)
    @relationship = custom_relationships(:contacts_deals)
  end

  test "should create record link" do
    assert_difference "CustomRecordLink.count", 1 do
      post record_links_path, params: {
        custom_record_link: {
          custom_relationship_id: @relationship.id,
          source_record_id: custom_records(:bob).id,
          target_record_id: custom_records(:deal_two).id
        }
      }
    end
  end

  test "should not create duplicate link" do
    assert_no_difference "CustomRecordLink.count" do
      post record_links_path, params: {
        custom_record_link: {
          custom_relationship_id: @relationship.id,
          source_record_id: custom_records(:alice).id,
          target_record_id: custom_records(:deal_one).id
        }
      }
    end
  end

  test "should not link target to multiple sources in one_to_many" do
    assert_no_difference "CustomRecordLink.count" do
      post record_links_path, params: {
        custom_record_link: {
          custom_relationship_id: @relationship.id,
          source_record_id: custom_records(:bob).id,
          target_record_id: custom_records(:deal_one).id
        }
      }
    end
  end

  test "should create self-referential link" do
    rel = custom_relationships(:contacts_self)
    assert_difference "CustomRecordLink.count", 1 do
      post record_links_path, params: {
        custom_record_link: {
          custom_relationship_id: rel.id,
          source_record_id: custom_records(:bob).id,
          target_record_id: custom_records(:alice).id
        }
      }
    end
  end

  test "should not link record to itself" do
    rel = custom_relationships(:contacts_self)
    assert_no_difference "CustomRecordLink.count" do
      post record_links_path, params: {
        custom_record_link: {
          custom_relationship_id: rel.id,
          source_record_id: custom_records(:alice).id,
          target_record_id: custom_records(:alice).id
        }
      }
    end
  end

  test "should destroy record link" do
    link = custom_record_links(:alice_deal_one)

    assert_difference "CustomRecordLink.count", -1 do
      delete record_link_path(link)
    end
  end

  test "should create symmetric link" do
    rel = custom_relationships(:contacts_knows)
    assert_difference "CustomRecordLink.count", 1 do
      post record_links_path, params: {
        custom_record_link: {
          custom_relationship_id: rel.id,
          source_record_id: custom_records(:alice).id,
          target_record_id: custom_records(:bob).id
        }
      }
    end
  end

  test "should block reverse duplicate on symmetric link" do
    rel = custom_relationships(:contacts_knows)
    CustomRecordLink.create!(
      custom_relationship: rel,
      source_record: custom_records(:alice),
      target_record: custom_records(:bob)
    )

    assert_no_difference "CustomRecordLink.count" do
      post record_links_path, params: {
        custom_record_link: {
          custom_relationship_id: rel.id,
          source_record_id: custom_records(:bob).id,
          target_record_id: custom_records(:alice).id
        }
      }
    end
  end
end
