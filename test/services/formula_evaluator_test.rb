require "test_helper"

class FormulaEvaluatorTest < ActiveSupport::TestCase
  # --- Template mode ---

  test "template mode replaces column references" do
    result = FormulaEvaluator.evaluate("{First Name} {Last Name}", { "First Name" => "William", "Last Name" => "Jackson" })
    assert_equal "William Jackson", result
  end

  test "template mode collapses whitespace from blank values" do
    result = FormulaEvaluator.evaluate("{First} {Middle} {Last}", { "First" => "William", "Middle" => nil, "Last" => "Jackson" })
    assert_equal "William Jackson", result
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

  test "formula mode concatenation with &" do
    result = FormulaEvaluator.evaluate('={First} & " " & {Last}', { "First" => "William", "Last" => "Jackson" })
    assert_equal "William Jackson", result
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

  # --- Complex formulas ---

  test "nested function calls" do
    result = FormulaEvaluator.evaluate('=UPPER({First} & " " & {Last})', { "First" => "william", "Last" => "jackson" })
    assert_equal "WILLIAM JACKSON", result
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
    result = FormulaEvaluator.evaluate("={Name}[0] & \" and \" & {Name}[1]", { "Name[0]" => "Alice", "Name[1]" => "Bob" })
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
end
