class FormulaEvaluator
  class Error < StandardError; end

  # Result wrapper for typed casting functions
  TypedResult = Struct.new(:value, :result_type, keyword_init: true)

  # AST Nodes
  ColumnRef = Struct.new(:name, :index, keyword_init: true)
  StringLiteral = Struct.new(:value, keyword_init: true)
  NumberLiteral = Struct.new(:value, keyword_init: true)
  BooleanLiteral = Struct.new(:value, keyword_init: true)
  BinaryOp = Struct.new(:op, :left, :right, keyword_init: true)
  UnaryOp = Struct.new(:op, :operand, keyword_init: true)
  FunctionCall = Struct.new(:name, :args, keyword_init: true)

  # Token
  Token = Struct.new(:type, :value, keyword_init: true)

  def self.truthy?(val)
    case val
    when nil, false then false
    when String then val != "" && val != "0"
    when Numeric then val != 0
    else true
    end
  end

  FUNCTIONS = {
    "IF" => ->(args) {
      raise Error, "IF requires 2 or 3 arguments" unless args.length.in?(2..3)
      if FormulaEvaluator.truthy?(args[0])
        args[1]
      else
        args.length == 3 ? args[2] : ""
      end
    },
    "UPPER" => ->(args) {
      raise Error, "UPPER requires 1 argument" unless args.length == 1
      args[0].to_s.upcase
    },
    "LOWER" => ->(args) {
      raise Error, "LOWER requires 1 argument" unless args.length == 1
      args[0].to_s.downcase
    },
    "SPLIT" => ->(args) {
      raise Error, "SPLIT requires 3 arguments" unless args.length == 3
      text = args[0].to_s
      delimiter = args[1].to_s
      index = args[2].to_i
      parts = text.split(delimiter)
      index < 0 ? parts[index] : parts[index]
    },

    # String functions
    "TRIM" => ->(args) {
      raise Error, "TRIM requires 1 argument" unless args.length == 1
      args[0].to_s.strip
    },
    "LEN" => ->(args) {
      raise Error, "LEN requires 1 argument" unless args.length == 1
      args[0].to_s.length
    },
    "LEFT" => ->(args) {
      raise Error, "LEFT requires 2 arguments" unless args.length == 2
      args[0].to_s[0, args[1].to_i]
    },
    "RIGHT" => ->(args) {
      raise Error, "RIGHT requires 2 arguments" unless args.length == 2
      text = args[0].to_s
      count = args[1].to_i
      count > text.length ? text : text[-count..]
    },
    "REPLACE" => ->(args) {
      raise Error, "REPLACE requires 3 or 4 arguments" unless args.length.in?(3..4)
      text = args[0].to_s
      old = args[1].to_s
      replacement = args[2].to_s
      if args.length == 4
        count = args[3].to_i
        count.times { text = text.sub(old, replacement) }
        text
      else
        text.gsub(old, replacement)
      end
    },
    "CONTAINS" => ->(args) {
      raise Error, "CONTAINS requires 2 arguments" unless args.length == 2
      args[0].to_s.include?(args[1].to_s)
    },
    "CONCAT" => ->(args) {
      raise Error, "CONCAT requires at least 1 argument" if args.empty?
      args.map(&:to_s).join
    },

    # Logical functions
    "AND" => ->(args) {
      raise Error, "AND requires at least 2 arguments" unless args.length >= 2
      args.all? { |a| FormulaEvaluator.truthy?(a) }
    },
    "OR" => ->(args) {
      raise Error, "OR requires at least 2 arguments" unless args.length >= 2
      args.any? { |a| FormulaEvaluator.truthy?(a) }
    },
    "NOT" => ->(args) {
      raise Error, "NOT requires 1 argument" unless args.length == 1
      !FormulaEvaluator.truthy?(args[0])
    },

    # Math functions
    "ROUND" => ->(args) {
      raise Error, "ROUND requires 1 or 2 arguments" unless args.length.in?(1..2)
      number = args[0].is_a?(Numeric) ? args[0] : args[0].to_f
      decimals = args.length == 2 ? args[1].to_i : 0
      number.round(decimals)
    },
    "ABS" => ->(args) {
      raise Error, "ABS requires 1 argument" unless args.length == 1
      val = args[0].is_a?(Numeric) ? args[0] : args[0].to_f
      val.abs
    },
    "FLOOR" => ->(args) {
      raise Error, "FLOOR requires 1 argument" unless args.length == 1
      val = args[0].is_a?(Numeric) ? args[0] : args[0].to_f
      val.floor
    },
    "CEIL" => ->(args) {
      raise Error, "CEIL requires 1 argument" unless args.length == 1
      val = args[0].is_a?(Numeric) ? args[0] : args[0].to_f
      val.ceil
    },
    "MIN" => ->(args) {
      raise Error, "MIN requires at least 2 arguments" unless args.length >= 2
      args.map { |a| a.is_a?(Numeric) ? a : a.to_f }.min
    },
    "MAX" => ->(args) {
      raise Error, "MAX requires at least 2 arguments" unless args.length >= 2
      args.map { |a| a.is_a?(Numeric) ? a : a.to_f }.max
    },
    "SUM" => ->(args) {
      raise Error, "SUM requires at least 1 argument" if args.empty?
      args.sum { |a| a.is_a?(Numeric) ? a : a.to_f }
    },

    # Utility functions
    "COALESCE" => ->(args) {
      raise Error, "COALESCE requires at least 1 argument" if args.empty?
      args.find { |a| FormulaEvaluator.truthy?(a) } || ""
    },

    # Type casting functions
    "NUMBER" => ->(args) {
      raise Error, "NUMBER requires 1 argument" unless args.length == 1
      val = args[0]
      case val
      when Numeric then val
      when TrueClass then 1
      when FalseClass then 0
      when NilClass then 0
      when String
        return 0 if val.strip.empty?
        val.include?(".") ? Float(val) : Integer(val)
      else
        val.to_f
      end
    },
    "TEXT" => ->(args) {
      raise Error, "TEXT requires 1 argument" unless args.length == 1
      val = args[0]
      case val
      when nil then ""
      when true then "true"
      when false then "false"
      else val.to_s
      end
    },
    "BOOLEAN" => ->(args) {
      raise Error, "BOOLEAN requires 1 argument" unless args.length == 1
      FormulaEvaluator.truthy?(args[0])
    },

    # Display-typed casting functions
    "CURRENCY" => ->(args) {
      raise Error, "CURRENCY requires 1 argument" unless args.length == 1
      val = args[0]
      num = case val
      when Numeric then val
      when String then val.strip.empty? ? 0 : Float(val)
      when NilClass then 0
      else val.to_f
      end
      TypedResult.new(value: BigDecimal(num.to_s).round(2), result_type: "currency")
    },
    "DATE" => ->(args) {
      raise Error, "DATE requires 1 or 3 arguments" unless args.length.in?([ 1, 3 ])
      begin
        date = if args.length == 3
          Date.new(args[0].to_i, args[1].to_i, args[2].to_i)
        else
          val = args[0]
          raise Error, "DATE received a blank value" if val.nil? || (val.is_a?(String) && val.strip.empty?)
          case val
          when Date then val
          when String
            date_str = val.include?("T") ? val.split("T").first : val
            Date.parse(date_str)
          else Date.parse(val.to_s)
          end
        end
        TypedResult.new(value: date, result_type: "date")
      rescue Date::Error => e
        raise Error, "DATE: #{e.message}"
      end
    },
    "TIME" => ->(args) {
      raise Error, "TIME requires 1 or 2 arguments" unless args.length.in?([ 1, 2 ])
      if args.length == 2
        h = args[0].to_i
        m = args[1].to_i
      else
        val = args[0].to_s
        raise Error, "TIME received a blank value" if val.strip.empty?
        val = val.split("T").last if val.include?("T")
        parts = val.split(":")
        h = parts[0].to_i
        m = parts[1].to_i
      end
      TypedResult.new(value: { h: h, m: m }, result_type: "time")
    },
    "DATETIME" => ->(args) {
      raise Error, "DATETIME requires 1 or 2 arguments" unless args.length.in?([ 1, 2 ])
      begin
        if args.length == 2
          date_val = args[0]
          time_val = args[1]
          raise Error, "DATETIME received a blank date" if date_val.nil? || (date_val.is_a?(String) && date_val.strip.empty?)
          date = date_val.is_a?(Date) ? date_val : Date.parse(date_val.to_s.split("T").first)
          if time_val.is_a?(Hash)
            h = time_val[:h]
            m = time_val[:m]
          else
            time_str = time_val.to_s
            time_str = time_str.split("T").last if time_str.include?("T")
            parts = time_str.split(":")
            h = parts[0].to_i
            m = parts[1].to_i
          end
          TypedResult.new(value: { date: date, h: h, m: m }, result_type: "datetime")
        else
          val = args[0].to_s
          raise Error, "DATETIME received a blank value" if val.strip.empty?
          date_part, time_part = val.split("T")
          date = Date.parse(date_part)
          parts = time_part.to_s.split(":")
          h = parts[0].to_i
          m = parts[1].to_i
          TypedResult.new(value: { date: date, h: h, m: m }, result_type: "datetime")
        end
      rescue Date::Error => e
        raise Error, "DATETIME: #{e.message}"
      end
    }
  }.freeze

  OPERATORS = %w[& + - * / = != <= >= < >].freeze
  COMPARISON_OPS = %w[= != < > <= >=].freeze
  ADDITION_OPS = %w[+ - &].freeze
  MULTIPLICATION_OPS = %w[* /].freeze

  def self.evaluate(formula, values)
    new(formula, values).evaluate
  end

  def self.evaluate_record(record, computed_columns)
    return if computed_columns.empty?

    all_columns = record.custom_table.custom_columns.order(:position)
    existing_values = record.custom_values.includes(:custom_column).index_by { |v| v.custom_column_id }

    # Build values hash keyed by column name, with positional index for duplicates
    values = {}
    name_counts = Hash.new(0)

    all_columns.each do |col|
      next if col.computed?
      cv = existing_values[col.id]
      raw = cv&.value

      val = case col.column_type
      when "boolean"
        raw == "1"
      when "number"
        raw.present? ? raw.to_i : nil
      when "decimal", "currency"
        raw.present? ? raw.to_f : nil
      else
        raw
      end

      idx = name_counts[col.name]
      if idx == 0
        values[col.name] = val
      end
      values["#{col.name}[#{idx}]"] = val
      name_counts[col.name] += 1
    end

    computed_columns.each do |col|
      result = evaluate(col.formula, values)
      is_error = result.is_a?(String) && result.start_with?("#ERROR:")

      if result.is_a?(TypedResult)
        inferred_type = result.result_type
        result_str = format_typed_value(result.value, inferred_type)
      else
        inferred_type = infer_type(result)
        result_str = format_for_storage(result, inferred_type)
      end

      cv = existing_values[col.id] || record.custom_values.build(custom_column: col)
      cv.value = result_str.presence
      cv.save!

      if !is_error && col.result_type != inferred_type
        col.update_column(:result_type, inferred_type)
      end
    end
  end

  def self.infer_type(value)
    case value
    when Integer then "number"
    when Float, BigDecimal then "decimal"
    when TrueClass, FalseClass then "boolean"
    else "text"
    end
  end

  def self.format_typed_value(value, type)
    case type
    when "currency"
      sprintf("%.2f", value)
    when "date"
      value.is_a?(Date) ? value.strftime("%Y-%m-%d") : Date.parse(value.to_s).strftime("%Y-%m-%d")
    when "time"
      sprintf("%02d:%02d", value[:h], value[:m])
    when "datetime"
      date_str = value[:date].strftime("%Y-%m-%d")
      time_str = sprintf("%02d:%02d", value[:h], value[:m])
      "#{date_str}T#{time_str}"
    else
      value.to_s
    end
  end

  def self.format_for_storage(value, type)
    case type
    when "boolean" then value ? "1" : "0"
    when "number" then value.to_i.to_s
    when "decimal" then value.to_s
    else value.to_s
    end
  end

  def initialize(formula, values)
    @formula = formula.to_s.strip
    @values = values
  end

  def evaluate
    return "" if @formula.empty?

    if @formula.start_with?("=")
      evaluate_formula_mode(@formula[1..])
    else
      evaluate_template_mode(@formula)
    end
  rescue Error => e
    "#ERROR: #{e.message}"
  end

  private

  # Template mode: replace {Column Name} and {Column Name}[index] with values
  def evaluate_template_mode(template)
    result = template.gsub(/\{([^}]+)\}(\[\d+\])?/) do
      col_name = $1
      index = $2 ? $2[1..-2].to_i : nil
      resolve_column(col_name, index).to_s
    end
    result.gsub(/\s+/, " ").strip
  end

  # Formula mode: tokenize → parse → evaluate AST
  def evaluate_formula_mode(formula)
    tokens = tokenize(formula)
    ast = parse(tokens)
    evaluate_node(ast)
  end

  # --- Tokenizer ---

  def tokenize(formula)
    tokens = []
    i = 0
    chars = formula.chars

    while i < chars.length
      ch = chars[i]

      if ch =~ /\s/
        i += 1
        next
      end

      # Column reference: {Column Name} or {Column Name}[0]
      if ch == "{"
        j = i + 1
        j += 1 while j < chars.length && chars[j] != "}"
        raise Error, "Unterminated column reference" if j >= chars.length
        col_name = chars[(i + 1)...j].join
        i = j + 1

        # Check for positional index [n]
        if i < chars.length && chars[i] == "["
          k = i + 1
          k += 1 while k < chars.length && chars[k] != "]"
          raise Error, "Unterminated index" if k >= chars.length
          index = chars[(i + 1)...k].join.to_i
          i = k + 1
          tokens << Token.new(type: :column_ref, value: [col_name, index])
        else
          tokens << Token.new(type: :column_ref, value: [col_name, nil])
        end
        next
      end

      # Double-quoted string
      if ch == '"'
        j = i + 1
        str = ""
        while j < chars.length && chars[j] != '"'
          str += chars[j]
          j += 1
        end
        raise Error, "Unterminated string" if j >= chars.length
        i = j + 1
        tokens << Token.new(type: :string, value: str)
        next
      end

      # Number
      if ch =~ /\d/ || (ch == "." && i + 1 < chars.length && chars[i + 1] =~ /\d/)
        num_str = ""
        num_str += chars[i] and i += 1 while i < chars.length && chars[i] =~ /[\d.]/
        tokens << Token.new(type: :number, value: num_str.include?(".") ? num_str.to_f : num_str.to_i)
        next
      end

      # Multi-character operators: !=, <=, >=
      if i + 1 < chars.length
        two = ch + chars[i + 1]
        if %w[!= <= >=].include?(two)
          tokens << Token.new(type: :operator, value: two)
          i += 2
          next
        end
      end

      # Single-character operators
      if %w[& + - * / = < >].include?(ch)
        tokens << Token.new(type: :operator, value: ch)
        i += 1
        next
      end

      # Parentheses and comma
      if ch == "("
        tokens << Token.new(type: :lparen, value: "(")
        i += 1
        next
      end

      if ch == ")"
        tokens << Token.new(type: :rparen, value: ")")
        i += 1
        next
      end

      if ch == ","
        tokens << Token.new(type: :comma, value: ",")
        i += 1
        next
      end

      # Identifier (function name or boolean)
      if ch =~ /[A-Za-z_]/
        j = i
        j += 1 while j < chars.length && chars[j] =~ /[A-Za-z_0-9]/
        word = chars[i...j].join
        i = j

        case word.upcase
        when "TRUE"
          tokens << Token.new(type: :boolean, value: true)
        when "FALSE"
          tokens << Token.new(type: :boolean, value: false)
        else
          tokens << Token.new(type: :function, value: word.upcase)
        end
        next
      end

      raise Error, "Unexpected character: #{ch}"
    end

    tokens
  end

  # --- Parser (recursive descent) ---

  def parse(tokens)
    @tokens = tokens
    @pos = 0
    node = parse_expression
    raise Error, "Unexpected tokens after expression" if @pos < @tokens.length
    node
  end

  def parse_expression
    parse_comparison
  end

  def parse_comparison
    left = parse_addition

    while @pos < @tokens.length && @tokens[@pos].type == :operator && COMPARISON_OPS.include?(@tokens[@pos].value)
      op = @tokens[@pos].value
      @pos += 1
      right = parse_addition
      left = BinaryOp.new(op: op, left: left, right: right)
    end

    left
  end

  IMPLICIT_CONCAT_STARTS = %i[column_ref string number boolean function lparen].freeze

  def parse_addition
    left = parse_multiplication

    loop do
      if @pos < @tokens.length && @tokens[@pos].type == :operator && ADDITION_OPS.include?(@tokens[@pos].value)
        op = @tokens[@pos].value
        @pos += 1
        right = parse_multiplication
        left = BinaryOp.new(op: op, left: left, right: right)
      elsif @pos < @tokens.length && IMPLICIT_CONCAT_STARTS.include?(@tokens[@pos].type)
        right = parse_multiplication
        left = BinaryOp.new(op: "&", left: left, right: right)
      else
        break
      end
    end

    left
  end

  def parse_multiplication
    left = parse_unary

    while @pos < @tokens.length && @tokens[@pos].type == :operator && MULTIPLICATION_OPS.include?(@tokens[@pos].value)
      op = @tokens[@pos].value
      @pos += 1
      right = parse_unary
      left = BinaryOp.new(op: op, left: left, right: right)
    end

    left
  end

  def parse_unary
    if @pos < @tokens.length && @tokens[@pos].type == :operator && @tokens[@pos].value == "-"
      @pos += 1
      operand = parse_unary
      return UnaryOp.new(op: "-", operand: operand)
    end

    parse_primary
  end

  def parse_primary
    raise Error, "Unexpected end of expression" if @pos >= @tokens.length

    token = @tokens[@pos]

    case token.type
    when :number
      @pos += 1
      NumberLiteral.new(value: token.value)
    when :string
      @pos += 1
      StringLiteral.new(value: token.value)
    when :boolean
      @pos += 1
      BooleanLiteral.new(value: token.value)
    when :column_ref
      @pos += 1
      ColumnRef.new(name: token.value[0], index: token.value[1])
    when :function
      name = token.value
      @pos += 1
      raise Error, "Expected ( after function #{name}" unless @pos < @tokens.length && @tokens[@pos].type == :lparen
      @pos += 1 # skip (

      args = []
      unless @pos < @tokens.length && @tokens[@pos].type == :rparen
        args << parse_expression
        while @pos < @tokens.length && @tokens[@pos].type == :comma
          @pos += 1
          args << parse_expression
        end
      end

      raise Error, "Expected ) after function arguments" unless @pos < @tokens.length && @tokens[@pos].type == :rparen
      @pos += 1 # skip )

      FunctionCall.new(name: name, args: args)
    when :lparen
      @pos += 1
      node = parse_expression
      raise Error, "Expected )" unless @pos < @tokens.length && @tokens[@pos].type == :rparen
      @pos += 1
      node
    else
      raise Error, "Unexpected token: #{token.type} (#{token.value})"
    end
  end

  # --- Evaluator ---

  def evaluate_node(node)
    case node
    when ColumnRef
      resolve_column(node.name, node.index)
    when StringLiteral
      node.value
    when NumberLiteral
      node.value
    when BooleanLiteral
      node.value
    when UnaryOp
      val = evaluate_node(node.operand)
      val = val.value if val.is_a?(TypedResult)
      case node.op
      when "-" then -to_number(val)
      end
    when BinaryOp
      evaluate_binary(node)
    when FunctionCall
      evaluate_function(node)
    else
      raise Error, "Unknown node type"
    end
  end

  def evaluate_binary(node)
    left = evaluate_node(node.left)
    right = evaluate_node(node.right)
    left = left.value if left.is_a?(TypedResult)
    right = right.value if right.is_a?(TypedResult)

    case node.op
    when "&"
      left.to_s + right.to_s
    when "+"
      to_number(left) + to_number(right)
    when "-"
      to_number(left) - to_number(right)
    when "*"
      to_number(left) * to_number(right)
    when "/"
      divisor = to_number(right)
      raise Error, "Division by zero" if divisor == 0
      to_number(left).to_f / divisor
    when "="
      left == right
    when "!="
      left != right
    when "<"
      compare(left, right) < 0
    when ">"
      compare(left, right) > 0
    when "<="
      compare(left, right) <= 0
    when ">="
      compare(left, right) >= 0
    end
  end

  TYPED_FUNCTIONS = %w[CURRENCY DATE TIME DATETIME].freeze

  def evaluate_function(node)
    func = FUNCTIONS[node.name]
    raise Error, "Unknown function: #{node.name}" unless func

    args = node.args.map { |arg| evaluate_node(arg) }

    if TYPED_FUNCTIONS.include?(node.name)
      # Unwrap TypedResult args for typed functions, passing raw values
      unwrapped = args.map { |a| a.is_a?(TypedResult) ? a.value : a }
      func.call(unwrapped)
    elsif node.name == "IF"
      func.call(args)
    else
      unwrapped = args.map { |a| a.is_a?(TypedResult) ? a.value : a }
      func.call(unwrapped)
    end
  end

  def resolve_column(name, index)
    if index
      key = "#{name}[#{index}]"
      @values[key]
    else
      @values[name]
    end
  end

  def to_number(val)
    case val
    when Numeric then val
    when String
      if val.include?(".")
        Float(val)
      else
        Integer(val)
      end
    when TrueClass then 1
    when FalseClass then 0
    when NilClass then 0
    else
      val.to_f
    end
  rescue ArgumentError, TypeError
    0
  end

  def compare(left, right)
    if left.is_a?(Numeric) && right.is_a?(Numeric)
      left <=> right
    else
      left.to_s <=> right.to_s
    end
  end
end
