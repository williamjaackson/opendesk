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

  test "select value accepts valid option" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:select), value: "Active")
    assert cv.valid?
  end

  test "select value rejects invalid option" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:select), value: "Unknown")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "is not a valid option"
  end

  test "select value allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:select), value: "")
    assert cv.valid?
  end

  test "linked select accepts valid linked value" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:linked_select), value: "Deal Alpha")
    assert cv.valid?
  end

  test "linked select rejects invalid linked value" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:linked_select), value: "Nonexistent Deal")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "is not a valid option"
  end

  test "linked select allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:linked_select), value: "")
    assert cv.valid?
  end

  test "text value matching regex is valid" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:regex_text), value: "123-4567")
    assert cv.valid?
  end

  test "text value not matching regex is invalid" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:regex_text), value: "bad")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "failed Phone Number check"
  end

  test "number value matching regex is valid" do
    column = custom_columns(:number)
    column.update_columns(regex_pattern: '^\d{3}$', regex_label: "Three Digits")
    cv = CustomValue.new(custom_record: @record, custom_column: column, value: "123")
    assert cv.valid?
  end

  test "blank value with regex still passes" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:regex_text), value: "")
    assert cv.valid?
  end

  test "currency value accepts valid amount" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:currency), value: "100.00")
    assert cv.valid?
  end

  test "currency value rejects no decimals" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:currency), value: "100")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid dollar amount"
  end

  test "currency value rejects one decimal place" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:currency), value: "100.5")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid dollar amount"
  end

  test "currency value rejects letters" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:currency), value: "abc")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid dollar amount"
  end

  test "currency value rejects dollar sign" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:currency), value: "$100.00")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid dollar amount"
  end

  test "currency value allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:currency), value: "")
    assert cv.valid?
  end

  test "colour value accepts valid hex" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:colour), value: "#ff0000")
    assert cv.valid?
  end

  test "colour value accepts uppercase hex" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:colour), value: "#FF0000")
    assert cv.valid?
  end

  test "colour value rejects missing hash" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:colour), value: "ff0000")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid hex colour (e.g. #ff0000)"
  end

  test "colour value rejects short hex" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:colour), value: "#fff")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid hex colour (e.g. #ff0000)"
  end

  test "colour value rejects non-hex characters" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:colour), value: "#gggggg")
    assert_not cv.valid?
    assert_includes cv.errors[:value], "must be a valid hex colour (e.g. #ff0000)"
  end

  test "colour value allows blank" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:colour), value: "")
    assert cv.valid?
  end

  test "text value with no regex set passes any value" do
    cv = CustomValue.new(custom_record: @record, custom_column: custom_columns(:name), value: "anything at all")
    assert cv.valid?
  end
end
