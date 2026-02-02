class FormulaEvaluator
  class Error < StandardError; end

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

  FUNCTIONS = {
    "IF" => ->(args) {
      raise Error, "IF requires 3 arguments" unless args.length == 3
      args[0] ? args[1] : args[2]
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
    }
  }.freeze

  OPERATORS = %w[& + - * / = != <= >= < >].freeze
  COMPARISON_OPS = %w[= != < > <= >=].freeze
  ADDITION_OPS = %w[+ - &].freeze
  MULTIPLICATION_OPS = %w[* /].freeze

  def self.evaluate(formula, values)
    new(formula, values).evaluate
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
    ""
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

  def parse_addition
    left = parse_multiplication

    while @pos < @tokens.length && @tokens[@pos].type == :operator && ADDITION_OPS.include?(@tokens[@pos].value)
      op = @tokens[@pos].value
      @pos += 1
      right = parse_multiplication
      left = BinaryOp.new(op: op, left: left, right: right)
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

  def evaluate_function(node)
    func = FUNCTIONS[node.name]
    raise Error, "Unknown function: #{node.name}" unless func

    if node.name == "IF"
      # Evaluate condition first, then only the matching branch
      condition = evaluate_node(node.args[0])
      then_val = evaluate_node(node.args[1])
      else_val = evaluate_node(node.args[2])
      func.call([condition, then_val, else_val])
    else
      args = node.args.map { |arg| evaluate_node(arg) }
      func.call(args)
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
