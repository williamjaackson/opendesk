require "test_helper"

class CustomValueTest < ActiveSupport::TestCase
  setup do
    @record = custom_records(:alice)
  end

  test "text value accepts any string" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:name), value: "anything goes")
    assert cv.valid?
  end

  test "number value accepts whole numbers" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:number), value: "123")
    assert cv.valid?
  end

  test "number value rejects non-numeric string" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:number), value: "abc")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a whole number"
  end

  test "number value rejects decimal" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:number), value: "12.5")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a whole number"
  end

  test "number value allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:number), value: "")
    assert cv.valid?
  end

  test "email value accepts valid email" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:email), value: "test@example.com")
    assert cv.valid?
  end

  test "email value rejects missing at sign" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:email), value: "notanemail")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid email address"
  end

  test "email value rejects spaces" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:email), value: "bad email@example.com")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid email address"
  end

  test "email value allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:email), value: "")
    assert cv.valid?
  end
end
