require "test_helper"

class CustomRelationshipTest < ActiveSupport::TestCase
  test "valid relationship" do
    rel = custom_relationships(:contacts_deals)
    assert rel.valid?
  end

  test "requires name" do
    rel = custom_relationships(:contacts_deals)
    rel.name = ""
    assert_not rel.valid?
  end

  test "requires inverse_name" do
    rel = custom_relationships(:contacts_deals)
    rel.inverse_name = ""
    assert_not rel.valid?
  end

  test "requires valid kind" do
    rel = CustomRelationship.new(
      source_table: custom_tables(:contacts),
      target_table: custom_tables(:deals),
      name: "Test",
      inverse_name: "Test Inv",
      kind: "invalid"
    )
    assert_not rel.valid?
  end

  test "allows self-referencing relationship" do
    rel = CustomRelationship.new(
      source_table: custom_tables(:contacts),
      target_table: custom_tables(:contacts),
      name: "Parent",
      inverse_name: "Children",
      kind: "has_many"
    )
    assert rel.valid?
  end

  test "destroying relationship destroys record links" do
    rel = custom_relationships(:contacts_deals)
    assert_difference "CustomRecordLink.count", -1 do
      rel.destroy
    end
  end
end
