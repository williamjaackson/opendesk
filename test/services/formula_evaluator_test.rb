require "test_helper"

class FormulaEvaluatorTest < ActiveSupport::TestCase
  # --- Template mode ---

  test "template mode replaces column references" do
    result = FormulaEvaluator.evaluate("{First Name} {Last Name}", { "First Name" => "Jane", "Last Name" => "Smith" })
    assert_equal "Jane Smith", result
  end

  test "template mode collapses whitespace from blank values" do
    result = FormulaEvaluator.evaluate("{First} {Middle} {Last}", { "First" => "Jane", "Middle" => nil, "Last" => "Smith" })
    assert_equal "Jane Smith", result
  end

  test "template mode strips leading and trailing whitespace" do
    result = FormulaEvaluator.evaluate("{Greeting} ", { "Greeting" => "Hello" })
    assert_equal "Hello", result
  end

  test "template mode returns empty string for empty formula" do
    assert_equal "", FormulaEvaluator.evaluate("", {})
  end

  test "template mode with positional index" do
    result = FormulaEvaluator.evaluate("{Name}[0] and {Name}[1]", { "Name[0]" => "Alice", "Name[1]" => "Bob" })
    assert_equal "Alice and Bob", result
  end

  # --- Formula mode: string concatenation ---

  test "formula mode explicit concatenation with &" do
    result = FormulaEvaluator.evaluate('={First} & " " & {Last}', { "First" => "Jane", "Last" => "Smith" })
    assert_equal "Jane Smith", result
  end

  test "formula mode implicit concatenation" do
    result = FormulaEvaluator.evaluate('={First} " " {Last}', { "First" => "Jane", "Last" => "Smith" })
    assert_equal "Jane Smith", result
  end

  test "implicit concatenation with no spaces" do
    result = FormulaEvaluator.evaluate('={First}" "{Last}', { "First" => "Jane", "Last" => "Smith" })
    assert_equal "Jane Smith", result
  end

  test "implicit concatenation with function call" do
    result = FormulaEvaluator.evaluate('={First} " " UPPER({Last})', { "First" => "Jane", "Last" => "smith" })
    assert_equal "Jane SMITH", result
  end

  test "implicit concatenation with IF" do
    result = FormulaEvaluator.evaluate('={First} IF({Middle}, " " {Middle}) " " {Last}', { "First" => "Jane", "Middle" => "Marie", "Last" => "Smith" })
    assert_equal "Jane Marie Smith", result
  end

  test "implicit concatenation with IF blank middle" do
    result = FormulaEvaluator.evaluate('={First} IF({Middle}, " " {Middle}) " " {Last}', { "First" => "Jane", "Middle" => "", "Last" => "Smith" })
    assert_equal "Jane Smith", result
  end

  # --- Formula mode: arithmetic ---

  test "formula mode addition" do
    result = FormulaEvaluator.evaluate("={A} + {B}", { "A" => 10, "B" => 20 })
    assert_equal 30, result
  end

  test "formula mode subtraction" do
    result = FormulaEvaluator.evaluate("={A} - {B}", { "A" => 50, "B" => 20 })
    assert_equal 30, result
  end

  test "formula mode multiplication" do
    result = FormulaEvaluator.evaluate("={A} * {B}", { "A" => 5, "B" => 6 })
    assert_equal 30, result
  end

  test "formula mode division" do
    result = FormulaEvaluator.evaluate("={A} / {B}", { "A" => 100, "B" => 4 })
    assert_equal 25.0, result
  end

  test "formula mode division by zero returns error" do
    result = FormulaEvaluator.evaluate("={A} / {B}", { "A" => 100, "B" => 0 })
    assert result.start_with?("#ERROR:")
  end

  test "formula mode operator precedence" do
    result = FormulaEvaluator.evaluate("=2 + 3 * 4", {})
    assert_equal 14, result
  end

  test "formula mode parentheses override precedence" do
    result = FormulaEvaluator.evaluate("=(2 + 3) * 4", {})
    assert_equal 20, result
  end

  test "formula mode unary minus" do
    result = FormulaEvaluator.evaluate("=-5 + 10", {})
    assert_equal 5, result
  end

  # --- Formula mode: comparisons ---

  test "formula mode equality" do
    assert_equal true, FormulaEvaluator.evaluate("=1 = 1", {})
    assert_equal false, FormulaEvaluator.evaluate("=1 = 2", {})
  end

  test "formula mode inequality" do
    assert_equal true, FormulaEvaluator.evaluate("=1 != 2", {})
    assert_equal false, FormulaEvaluator.evaluate("=1 != 1", {})
  end

  test "formula mode less than" do
    assert_equal true, FormulaEvaluator.evaluate("=1 < 2", {})
    assert_equal false, FormulaEvaluator.evaluate("=2 < 1", {})
  end

  test "formula mode greater than" do
    assert_equal true, FormulaEvaluator.evaluate("=2 > 1", {})
    assert_equal false, FormulaEvaluator.evaluate("=1 > 2", {})
  end

  test "formula mode less than or equal" do
    assert_equal true, FormulaEvaluator.evaluate("=1 <= 1", {})
    assert_equal true, FormulaEvaluator.evaluate("=1 <= 2", {})
    assert_equal false, FormulaEvaluator.evaluate("=2 <= 1", {})
  end

  test "formula mode greater than or equal" do
    assert_equal true, FormulaEvaluator.evaluate("=2 >= 2", {})
    assert_equal true, FormulaEvaluator.evaluate("=2 >= 1", {})
    assert_equal false, FormulaEvaluator.evaluate("=1 >= 2", {})
  end

  # --- Formula mode: literals ---

  test "formula mode string literal" do
    result = FormulaEvaluator.evaluate('="hello"', {})
    assert_equal "hello", result
  end

  test "formula mode number literal" do
    assert_equal 42, FormulaEvaluator.evaluate("=42", {})
    assert_equal 3.14, FormulaEvaluator.evaluate("=3.14", {})
  end

  test "formula mode boolean literals" do
    assert_equal true, FormulaEvaluator.evaluate("=TRUE", {})
    assert_equal false, FormulaEvaluator.evaluate("=FALSE", {})
  end

  # --- Functions ---

  test "IF returns then value when truthy" do
    result = FormulaEvaluator.evaluate('=IF(TRUE, "yes", "no")', {})
    assert_equal "yes", result
  end

  test "IF returns else value when falsy" do
    result = FormulaEvaluator.evaluate('=IF(FALSE, "yes", "no")', {})
    assert_equal "no", result
  end

  test "IF with comparison condition" do
    result = FormulaEvaluator.evaluate('=IF({Active}, "Active", "Inactive")', { "Active" => true })
    assert_equal "Active", result
  end

  test "IF with nil condition is falsy" do
    result = FormulaEvaluator.evaluate('=IF({Active}, "Active", "Inactive")', { "Active" => nil })
    assert_equal "Inactive", result
  end

  test "IF treats empty string as falsy" do
    result = FormulaEvaluator.evaluate('=IF({Name}, "present", "blank")', { "Name" => "" })
    assert_equal "blank", result
  end

  test "IF treats non-empty string as truthy" do
    result = FormulaEvaluator.evaluate('=IF({Name}, "present", "blank")', { "Name" => "Alice" })
    assert_equal "present", result
  end

  test "IF treats zero as falsy" do
    result = FormulaEvaluator.evaluate('=IF({Count}, "has items", "empty")', { "Count" => 0 })
    assert_equal "empty", result
  end

  test "IF treats string 0 as falsy for boolean columns" do
    result = FormulaEvaluator.evaluate('=IF({Active}, "yes", "no")', { "Active" => "0" })
    assert_equal "no", result
  end

  test "UPPER converts to uppercase" do
    result = FormulaEvaluator.evaluate('=UPPER("hello")', {})
    assert_equal "HELLO", result
  end

  test "UPPER with column reference" do
    result = FormulaEvaluator.evaluate("=UPPER({Name})", { "Name" => "alice" })
    assert_equal "ALICE", result
  end

  test "LOWER converts to lowercase" do
    result = FormulaEvaluator.evaluate('=LOWER("HELLO")', {})
    assert_equal "hello", result
  end

  test "SPLIT returns element at index" do
    result = FormulaEvaluator.evaluate('=SPLIT("a,b,c", ",", 1)', {})
    assert_equal "b", result
  end

  test "SPLIT with negative index counts from end" do
    result = FormulaEvaluator.evaluate('=SPLIT("a,b,c", ",", -1)', {})
    assert_equal "c", result
  end

  # --- String functions ---

  test "TRIM removes whitespace" do
    assert_equal "hello", FormulaEvaluator.evaluate('=TRIM("  hello  ")', {})
  end

  test "LEN returns string length" do
    assert_equal 5, FormulaEvaluator.evaluate('=LEN("hello")', {})
    assert_equal 0, FormulaEvaluator.evaluate('=LEN("")', {})
  end

  test "LEFT returns first N characters" do
    assert_equal "hel", FormulaEvaluator.evaluate('=LEFT("hello", 3)', {})
  end

  test "RIGHT returns last N characters" do
    assert_equal "llo", FormulaEvaluator.evaluate('=RIGHT("hello", 3)', {})
  end

  test "RIGHT with count greater than length returns full string" do
    assert_equal "hi", FormulaEvaluator.evaluate('=RIGHT("hi", 10)', {})
  end

  test "REPLACE replaces occurrences" do
    assert_equal "hello world", FormulaEvaluator.evaluate('=REPLACE("hello there", "there", "world")', {})
  end

  test "REPLACE replaces all occurrences" do
    assert_equal "b-b-b", FormulaEvaluator.evaluate('=REPLACE("a-a-a", "a", "b")', {})
  end

  test "REPLACE with occurrence count replaces only N times" do
    assert_equal "b-b-a", FormulaEvaluator.evaluate('=REPLACE("a-a-a", "a", "b", 2)', {})
  end

  test "REPLACE with occurrence count of 1 replaces first only" do
    assert_equal "b-a-a", FormulaEvaluator.evaluate('=REPLACE("a-a-a", "a", "b", 1)', {})
  end

  test "CONTAINS returns true when found" do
    assert_equal true, FormulaEvaluator.evaluate('=CONTAINS("hello world", "world")', {})
  end

  test "CONTAINS returns false when not found" do
    assert_equal false, FormulaEvaluator.evaluate('=CONTAINS("hello world", "xyz")', {})
  end

  test "CONCAT joins multiple arguments" do
    assert_equal "abc", FormulaEvaluator.evaluate('=CONCAT("a", "b", "c")', {})
  end

  test "CONCAT with column references" do
    result = FormulaEvaluator.evaluate('=CONCAT({First}, " ", {Last})', { "First" => "Jane", "Last" => "Smith" })
    assert_equal "Jane Smith", result
  end

  # --- Logical functions ---

  test "AND returns true when all truthy" do
    assert_equal true, FormulaEvaluator.evaluate('=AND(TRUE, TRUE, TRUE)', {})
  end

  test "AND returns false when any falsy" do
    assert_equal false, FormulaEvaluator.evaluate('=AND(TRUE, FALSE, TRUE)', {})
  end

  test "AND with column references" do
    assert_equal true, FormulaEvaluator.evaluate('=AND({A}, {B})', { "A" => "yes", "B" => 1 })
    assert_equal false, FormulaEvaluator.evaluate('=AND({A}, {B})', { "A" => "yes", "B" => "" })
  end

  test "OR returns true when any truthy" do
    assert_equal true, FormulaEvaluator.evaluate('=OR(FALSE, TRUE)', {})
  end

  test "OR returns false when all falsy" do
    assert_equal false, FormulaEvaluator.evaluate('=OR(FALSE, FALSE, 0)', {})
  end

  test "NOT negates truthiness" do
    assert_equal false, FormulaEvaluator.evaluate('=NOT(TRUE)', {})
    assert_equal true, FormulaEvaluator.evaluate('=NOT(FALSE)', {})
    assert_equal true, FormulaEvaluator.evaluate('=NOT("")', {})
  end

  test "IF with AND condition" do
    result = FormulaEvaluator.evaluate('=IF(AND({A}, {B}), "both", "nope")', { "A" => true, "B" => true })
    assert_equal "both", result
  end

  # --- Math functions ---

  test "ROUND with default decimals" do
    assert_equal 4, FormulaEvaluator.evaluate("=ROUND(3.7)", {})
  end

  test "ROUND to specific decimals" do
    assert_equal 3.14, FormulaEvaluator.evaluate("=ROUND(3.14159, 2)", {})
  end

  test "ABS of negative number" do
    assert_equal 5, FormulaEvaluator.evaluate("=ABS(-5)", {})
  end

  test "ABS of positive number" do
    assert_equal 5, FormulaEvaluator.evaluate("=ABS(5)", {})
  end

  test "FLOOR rounds down" do
    assert_equal 3, FormulaEvaluator.evaluate("=FLOOR(3.7)", {})
    assert_equal(-4, FormulaEvaluator.evaluate("=FLOOR(-3.2)", {}))
  end

  test "CEIL rounds up" do
    assert_equal 4, FormulaEvaluator.evaluate("=CEIL(3.2)", {})
    assert_equal(-3, FormulaEvaluator.evaluate("=CEIL(-3.7)", {}))
  end

  test "MIN returns smallest value" do
    assert_equal 1, FormulaEvaluator.evaluate("=MIN(3, 1, 2)", {})
  end

  test "MAX returns largest value" do
    assert_equal 3, FormulaEvaluator.evaluate("=MAX(1, 3, 2)", {})
  end

  test "MIN and MAX with column references" do
    assert_equal 10, FormulaEvaluator.evaluate("=MIN({A}, {B})", { "A" => 10, "B" => 20 })
    assert_equal 20, FormulaEvaluator.evaluate("=MAX({A}, {B})", { "A" => 10, "B" => 20 })
  end

  test "SUM adds multiple values" do
    assert_equal 15, FormulaEvaluator.evaluate("=SUM(1, 2, 3, 4, 5)", {})
  end

  test "SUM with column references" do
    assert_equal 60, FormulaEvaluator.evaluate("=SUM({A}, {B}, {C})", { "A" => 10, "B" => 20, "C" => 30 })
  end

  # --- Utility functions ---

  test "COALESCE returns first truthy value" do
    assert_equal "hello", FormulaEvaluator.evaluate('=COALESCE("", "", "hello", "world")', {})
  end

  test "COALESCE with nil column" do
    result = FormulaEvaluator.evaluate('=COALESCE({Nickname}, {Name})', { "Nickname" => nil, "Name" => "Alice" })
    assert_equal "Alice", result
  end

  test "COALESCE returns empty string when all falsy" do
    assert_equal "", FormulaEvaluator.evaluate('=COALESCE("", 0, FALSE)', {})
  end

  # --- Type casting functions ---

  test "NUMBER from string integer" do
    assert_equal 42, FormulaEvaluator.evaluate('=NUMBER("42")', {})
  end

  test "NUMBER from string decimal" do
    assert_equal 3.14, FormulaEvaluator.evaluate('=NUMBER("3.14")', {})
  end

  test "NUMBER from boolean" do
    assert_equal 1, FormulaEvaluator.evaluate("=NUMBER(TRUE)", {})
    assert_equal 0, FormulaEvaluator.evaluate("=NUMBER(FALSE)", {})
  end

  test "NUMBER from nil returns 0" do
    assert_equal 0, FormulaEvaluator.evaluate("=NUMBER({X})", { "X" => nil })
  end

  test "NUMBER from empty string returns 0" do
    assert_equal 0, FormulaEvaluator.evaluate('=NUMBER("")', {})
  end

  test "NUMBER passes through numeric values" do
    assert_equal 99, FormulaEvaluator.evaluate("=NUMBER(99)", {})
  end

  test "NUMBER enables arithmetic on string columns" do
    result = FormulaEvaluator.evaluate("=NUMBER({A}) + NUMBER({B})", { "A" => "10", "B" => "20" })
    assert_equal 30, result
  end

  test "TEXT from number" do
    assert_equal "42", FormulaEvaluator.evaluate("=TEXT(42)", {})
    assert_equal "3.14", FormulaEvaluator.evaluate("=TEXT(3.14)", {})
  end

  test "TEXT from boolean" do
    assert_equal "true", FormulaEvaluator.evaluate("=TEXT(TRUE)", {})
    assert_equal "false", FormulaEvaluator.evaluate("=TEXT(FALSE)", {})
  end

  test "TEXT from nil returns empty string" do
    assert_equal "", FormulaEvaluator.evaluate("=TEXT({X})", { "X" => nil })
  end

  test "TEXT passes through string values" do
    assert_equal "hello", FormulaEvaluator.evaluate('=TEXT("hello")', {})
  end

  test "BOOLEAN from truthy values" do
    assert_equal true, FormulaEvaluator.evaluate('=BOOLEAN("hello")', {})
    assert_equal true, FormulaEvaluator.evaluate("=BOOLEAN(1)", {})
    assert_equal true, FormulaEvaluator.evaluate("=BOOLEAN(TRUE)", {})
  end

  test "BOOLEAN from falsy values" do
    assert_equal false, FormulaEvaluator.evaluate('=BOOLEAN("")', {})
    assert_equal false, FormulaEvaluator.evaluate("=BOOLEAN(0)", {})
    assert_equal false, FormulaEvaluator.evaluate("=BOOLEAN(FALSE)", {})
  end

  test "BOOLEAN with column reference" do
    assert_equal true, FormulaEvaluator.evaluate("=BOOLEAN({Active})", { "Active" => "1" })
    assert_equal false, FormulaEvaluator.evaluate("=BOOLEAN({Active})", { "Active" => "0" })
  end

  # --- Complex formulas ---

  test "nested function calls" do
    result = FormulaEvaluator.evaluate('=UPPER({First} " " {Last})', { "First" => "jane", "Last" => "smith" })
    assert_equal "JANE SMITH", result
  end

  test "IF with UPPER" do
    result = FormulaEvaluator.evaluate('=IF({Active}, UPPER({Name}), "Inactive")', { "Active" => true, "Name" => "alice" })
    assert_equal "ALICE", result
  end

  test "arithmetic with string column values" do
    result = FormulaEvaluator.evaluate("={Price} * {Qty}", { "Price" => "10.50", "Qty" => "3" })
    assert_in_delta 31.5, result, 0.001
  end

  # --- Column references with positional index ---

  test "formula mode column ref with positional index" do
    result = FormulaEvaluator.evaluate('={Name}[0] " and " {Name}[1]', { "Name[0]" => "Alice", "Name[1]" => "Bob" })
    assert_equal "Alice and Bob", result
  end

  # --- Edge cases ---

  test "nil column value in arithmetic treated as zero" do
    result = FormulaEvaluator.evaluate("={A} + {B}", { "A" => 5, "B" => nil })
    assert_equal 5, result
  end

  test "missing column reference returns nil" do
    result = FormulaEvaluator.evaluate("={Missing}", {})
    assert_nil result
  end

  test "invalid formula returns error string" do
    result = FormulaEvaluator.evaluate("=IF(", {})
    assert result.start_with?("#ERROR:")
  end

  test "IF with 2 arguments returns empty string for falsy" do
    result = FormulaEvaluator.evaluate('=IF({Name}, "present")', { "Name" => "" })
    assert_equal "", result
  end

  test "IF with 2 arguments returns then value for truthy" do
    result = FormulaEvaluator.evaluate('=IF({Name}, "present")', { "Name" => "Alice" })
    assert_equal "present", result
  end

  test "IF does not evaluate the untaken branch" do
    # DATE({X}) would error on blank, but IF should not evaluate it
    result = FormulaEvaluator.evaluate('=IF({X}, DATE({X}), "")', { "X" => nil })
    assert_equal "", result
  end

  test "string number coercion for addition" do
    result = FormulaEvaluator.evaluate("={A} + {B}", { "A" => "10", "B" => "20" })
    assert_equal 30, result
  end

  test "boolean true coerces to 1 for arithmetic" do
    result = FormulaEvaluator.evaluate("={A} + 1", { "A" => true })
    assert_equal 2, result
  end

  test "boolean false coerces to 0 for arithmetic" do
    result = FormulaEvaluator.evaluate("={A} + 1", { "A" => false })
    assert_equal 1, result
  end

  test "decimal numbers in formulas" do
    result = FormulaEvaluator.evaluate("=1.5 + 2.5", {})
    assert_equal 4.0, result
  end

  # --- Display-typed casting functions ---

  test "CURRENCY wraps value as TypedResult with currency type" do
    result = FormulaEvaluator.evaluate("=CURRENCY(42.567)", {})
    assert_instance_of FormulaEvaluator::TypedResult, result
    assert_equal "currency", result.result_type
    assert_equal BigDecimal("42.57"), result.value
  end

  test "CURRENCY with column reference" do
    result = FormulaEvaluator.evaluate("=CURRENCY({Price})", { "Price" => 99.999 })
    assert_equal BigDecimal("100.00"), result.value
    assert_equal "currency", result.result_type
  end

  test "CURRENCY with string value" do
    result = FormulaEvaluator.evaluate('=CURRENCY("19.99")', {})
    assert_equal BigDecimal("19.99"), result.value
  end

  test "DATE from string" do
    result = FormulaEvaluator.evaluate('=DATE("2024-03-15")', {})
    assert_instance_of FormulaEvaluator::TypedResult, result
    assert_equal "date", result.result_type
    assert_equal Date.new(2024, 3, 15), result.value
  end

  test "DATE from year month day" do
    result = FormulaEvaluator.evaluate("=DATE(2024, 3, 15)", {})
    assert_equal Date.new(2024, 3, 15), result.value
    assert_equal "date", result.result_type
  end

  test "TIME from string" do
    result = FormulaEvaluator.evaluate('=TIME("14:30")', {})
    assert_instance_of FormulaEvaluator::TypedResult, result
    assert_equal "time", result.result_type
    assert_equal({ h: 14, m: 30 }, result.value)
  end

  test "TIME extracts time from datetime string" do
    result = FormulaEvaluator.evaluate('=TIME("2026-03-12T05:30")', {})
    assert_equal({ h: 5, m: 30 }, result.value)
  end

  test "TIME errors on blank value" do
    result = FormulaEvaluator.evaluate("=TIME({X})", { "X" => nil })
    assert result.start_with?("#ERROR:")
  end

  test "DATE extracts date from datetime string" do
    result = FormulaEvaluator.evaluate('=DATE("2026-03-12T05:30")', {})
    assert_equal Date.new(2026, 3, 12), result.value
  end

  test "DATE errors on blank value" do
    result = FormulaEvaluator.evaluate("=DATE({X})", { "X" => nil })
    assert result.start_with?("#ERROR:")
  end

  test "DATETIME errors on blank value" do
    result = FormulaEvaluator.evaluate("=DATETIME({X})", { "X" => nil })
    assert result.start_with?("#ERROR:")
  end

  test "TIME from hours and minutes" do
    result = FormulaEvaluator.evaluate("=TIME(14, 30)", {})
    assert_equal({ h: 14, m: 30 }, result.value)
    assert_equal "time", result.result_type
  end

  test "DATETIME from string" do
    result = FormulaEvaluator.evaluate('=DATETIME("2024-03-15T14:30")', {})
    assert_instance_of FormulaEvaluator::TypedResult, result
    assert_equal "datetime", result.result_type
    assert_equal Date.new(2024, 3, 15), result.value[:date]
    assert_equal 14, result.value[:h]
    assert_equal 30, result.value[:m]
  end

  test "DATETIME from date and time args" do
    # Simulate passing results from DATE and TIME functions (unwrapped)
    result = FormulaEvaluator.evaluate('=DATETIME("2024-03-15", "09:45")', {})
    assert_equal "datetime", result.result_type
    assert_equal Date.new(2024, 3, 15), result.value[:date]
    assert_equal 9, result.value[:h]
    assert_equal 45, result.value[:m]
  end

  test "TypedResult is unwrapped for arithmetic" do
    result = FormulaEvaluator.evaluate("=CURRENCY({Price}) + 10", { "Price" => 5.0 })
    # The + operator unwraps TypedResult, so result is a plain number
    assert_not_instance_of FormulaEvaluator::TypedResult, result
    assert_in_delta 15.0, result, 0.01
  end

  test "TypedResult is unwrapped for comparison" do
    result = FormulaEvaluator.evaluate("=CURRENCY({Price}) > 5", { "Price" => 10.0 })
    assert_equal true, result
  end

  # --- Type inference ---

  test "infer_type returns number for Integer" do
    assert_equal "number", FormulaEvaluator.infer_type(42)
  end

  test "infer_type returns decimal for Float" do
    assert_equal "decimal", FormulaEvaluator.infer_type(3.14)
  end

  test "infer_type returns boolean for true/false" do
    assert_equal "boolean", FormulaEvaluator.infer_type(true)
    assert_equal "boolean", FormulaEvaluator.infer_type(false)
  end

  test "infer_type returns text for String" do
    assert_equal "text", FormulaEvaluator.infer_type("hello")
  end

  # --- Storage formatting ---

  test "format_typed_value formats currency" do
    assert_equal "42.57", FormulaEvaluator.format_typed_value(BigDecimal("42.567"), "currency")
  end

  test "format_typed_value formats date" do
    assert_equal "2024-03-15", FormulaEvaluator.format_typed_value(Date.new(2024, 3, 15), "date")
  end

  test "format_typed_value formats time" do
    assert_equal "14:30", FormulaEvaluator.format_typed_value({ h: 14, m: 30 }, "time")
  end

  test "format_typed_value formats datetime" do
    assert_equal "2024-03-15T14:30", FormulaEvaluator.format_typed_value({ date: Date.new(2024, 3, 15), h: 14, m: 30 }, "datetime")
  end

  test "format_for_storage formats boolean" do
    assert_equal "1", FormulaEvaluator.format_for_storage(true, "boolean")
    assert_equal "0", FormulaEvaluator.format_for_storage(false, "boolean")
  end

  test "format_for_storage formats number" do
    assert_equal "42", FormulaEvaluator.format_for_storage(42, "number")
  end

  test "format_for_storage formats decimal" do
    assert_equal "3.14", FormulaEvaluator.format_for_storage(3.14, "decimal")
  end

  test "integer arithmetic infers number type" do
    result = FormulaEvaluator.evaluate("={Qty} * 2", { "Qty" => 5 })
    assert_equal 10, result
    assert_equal "number", FormulaEvaluator.infer_type(result)
  end

  test "float arithmetic infers decimal type" do
    result = FormulaEvaluator.evaluate("={Price} * 1.1", { "Price" => 10.0 })
    assert_in_delta 11.0, result, 0.001
    assert_equal "decimal", FormulaEvaluator.infer_type(result)
  end

  test "boolean function infers boolean type" do
    result = FormulaEvaluator.evaluate("=AND({A}, {B})", { "A" => true, "B" => true })
    assert_equal true, result
    assert_equal "boolean", FormulaEvaluator.infer_type(result)
  end
end
