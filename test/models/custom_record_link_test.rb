require "test_helper"

class CustomRecordLinkTest < ActiveSupport::TestCase
  test "valid record link" do
    link = custom_record_links(:alice_deal_one)
    assert link.valid?
  end

  test "prevents duplicate links" do
    link = CustomRecordLink.new(
      custom_relationship: custom_relationships(:contacts_deals),
      source_record: custom_records(:alice),
      target_record: custom_records(:deal_one)
    )
    assert_not link.valid?
  end

  test "one_to_many prevents target linking to multiple sources" do
    link = CustomRecordLink.new(
      custom_relationship: custom_relationships(:contacts_deals),
      source_record: custom_records(:bob),
      target_record: custom_records(:deal_one)
    )
    assert_not link.valid?
  end

  test "allows linking different target" do
    link = CustomRecordLink.new(
      custom_relationship: custom_relationships(:contacts_deals),
      source_record: custom_records(:alice),
      target_record: custom_records(:deal_two)
    )
    assert link.valid?
  end

  test "one_to_one prevents source from linking to multiple targets" do
    CustomRecordLink.create!(
      custom_relationship: custom_relationships(:deals_projects),
      source_record: custom_records(:deal_one),
      target_record: custom_records(:project_one)
    )
    link = CustomRecordLink.new(
      custom_relationship: custom_relationships(:deals_projects),
      source_record: custom_records(:deal_one),
      target_record: custom_records(:project_two)
    )
    assert_not link.valid?
  end

  test "one_to_one prevents target from linking to multiple sources" do
    CustomRecordLink.create!(
      custom_relationship: custom_relationships(:deals_projects),
      source_record: custom_records(:deal_one),
      target_record: custom_records(:project_one)
    )
    link = CustomRecordLink.new(
      custom_relationship: custom_relationships(:deals_projects),
      source_record: custom_records(:deal_two),
      target_record: custom_records(:project_one)
    )
    assert_not link.valid?
  end

  test "many_to_one prevents source from linking to multiple targets" do
    CustomRecordLink.create!(
      custom_relationship: custom_relationships(:projects_contacts),
      source_record: custom_records(:project_one),
      target_record: custom_records(:alice)
    )
    link = CustomRecordLink.new(
      custom_relationship: custom_relationships(:projects_contacts),
      source_record: custom_records(:project_one),
      target_record: custom_records(:bob)
    )
    assert_not link.valid?
  end

  test "many_to_one allows target to be linked from multiple sources" do
    CustomRecordLink.create!(
      custom_relationship: custom_relationships(:projects_contacts),
      source_record: custom_records(:project_one),
      target_record: custom_records(:alice)
    )
    link = CustomRecordLink.new(
      custom_relationship: custom_relationships(:projects_contacts),
      source_record: custom_records(:project_two),
      target_record: custom_records(:alice)
    )
    assert link.valid?
  end
end
