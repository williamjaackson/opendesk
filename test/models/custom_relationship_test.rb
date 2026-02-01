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
      kind: "one_to_many"
    )
    assert rel.valid?
  end

  test "destroying relationship destroys record links" do
    rel = custom_relationships(:contacts_deals)
    assert_difference "CustomRecordLink.count", -1 do
      rel.destroy
    end
  end

  test "self_referential? returns true for self-referential" do
    assert custom_relationships(:contacts_self).self_referential?
  end

  test "self_referential? returns false for non-self-referential" do
    assert_not custom_relationships(:contacts_deals).self_referential?
  end

  test "auto-sets symmetric for one-to-one self-referential" do
    rel = CustomRelationship.new(
      source_table: custom_tables(:contacts),
      target_table: custom_tables(:contacts),
      name: "Partner",
      inverse_name: "anything",
      kind: "one_to_one"
    )
    rel.valid?
    assert rel.symmetric?
  end

  test "mirrors inverse_name from name when symmetric" do
    rel = CustomRelationship.new(
      source_table: custom_tables(:contacts),
      target_table: custom_tables(:contacts),
      name: "Partner",
      inverse_name: "something else",
      kind: "one_to_one"
    )
    rel.valid?
    assert_equal "Partner", rel.inverse_name
  end

  test "symmetric requires self-referential" do
    rel = CustomRelationship.new(
      source_table: custom_tables(:contacts),
      target_table: custom_tables(:deals),
      name: "Test",
      inverse_name: "Test Inv",
      kind: "many_to_many",
      symmetric: true
    )
    assert_not rel.valid?
    assert rel.errors[:symmetric].any?
  end

  test "symmetric not allowed on one-to-many" do
    rel = CustomRelationship.new(
      source_table: custom_tables(:contacts),
      target_table: custom_tables(:contacts),
      name: "Test",
      inverse_name: "Test Inv",
      kind: "one_to_many",
      symmetric: true
    )
    assert_not rel.valid?
    assert rel.errors[:symmetric].any?
  end

  test "symmetric not allowed on many-to-one" do
    rel = CustomRelationship.new(
      source_table: custom_tables(:contacts),
      target_table: custom_tables(:contacts),
      name: "Test",
      inverse_name: "Test Inv",
      kind: "many_to_one",
      symmetric: true
    )
    assert_not rel.valid?
    assert rel.errors[:symmetric].any?
  end

  test "symmetric allowed on many-to-many self-referential" do
    rel = custom_relationships(:contacts_knows)
    assert rel.valid?
    assert rel.symmetric?
  end
end
