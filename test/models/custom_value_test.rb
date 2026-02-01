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

  test "boolean value accepts 1" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:boolean), value: "1")
    assert cv.valid?
  end

  test "boolean value accepts 0" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:boolean), value: "0")
    assert cv.valid?
  end

  test "boolean value rejects true" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:boolean), value: "true")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be yes or no"
  end

  test "boolean value rejects abc" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:boolean), value: "abc")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be yes or no"
  end

  test "boolean value allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:boolean), value: "")
    assert cv.valid?
  end

  test "date value accepts valid ISO date" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:date), value: "2026-01-15")
    assert cv.valid?
  end

  test "date value rejects non-date string" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:date), value: "not-a-date")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid date"
  end

  test "date value rejects invalid month" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:date), value: "2026-13-01")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid date"
  end

  test "date value rejects invalid day" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:date), value: "2026-01-32")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid date"
  end

  test "date value rejects wrong format" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:date), value: "15/01/2026")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid date"
  end

  test "date value allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:date), value: "")
    assert cv.valid?
  end

  test "time value accepts valid 24h time" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:time), value: "14:30")
    assert cv.valid?
  end

  test "time value accepts midnight" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:time), value: "00:00")
    assert cv.valid?
  end

  test "time value accepts 23:59" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:time), value: "23:59")
    assert cv.valid?
  end

  test "time value rejects invalid hour 24:00" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:time), value: "24:00")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid time in HH:MM format"
  end

  test "time value rejects invalid minute 14:60" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:time), value: "14:60")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid time in HH:MM format"
  end

  test "time value rejects 12h format" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:time), value: "2:30 PM")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid time in HH:MM format"
  end

  test "time value rejects random string" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:time), value: "not a time")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid time in HH:MM format"
  end

  test "time value allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:time), value: "")
    assert cv.valid?
  end

  test "datetime value accepts valid datetime" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:datetime), value: "2026-01-15T14:30")
    assert cv.valid?
  end

  test "datetime value rejects non-datetime string" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:datetime), value: "not-a-datetime")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid date and time"
  end

  test "datetime value rejects date without time" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:datetime), value: "2026-01-15")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid date and time"
  end

  test "datetime value rejects wrong format" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:datetime), value: "15/01/2026 14:30")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid date and time"
  end

  test "datetime value allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:datetime), value: "")
    assert cv.valid?
  end
end
