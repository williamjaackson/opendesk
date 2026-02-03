module ApplicationHelper
  def relationship_kind_label(kind)
    case kind
    when "one_to_one" then "One to One"
    when "one_to_many" then "One to Many"
    when "many_to_one" then "Many to One"
    when "many_to_many" then "Many to Many"
    else kind.humanize
    end
  end

  def sample_value_for_type(column_type, variant: 1)
    case column_type
    when "text"
      variant == 1 ? "Example text" : "Another value"
    when "number"
      variant == 1 ? "42" : "108"
    when "decimal"
      variant == 1 ? "3.14" : "99.99"
    when "email"
      variant == 1 ? "alice@example.com" : "bob@example.com"
    when "boolean"
      variant == 1 ? "Yes" : "No"
    when "date"
      variant == 1 ? "2024-03-15" : "2024-06-20"
    when "time"
      variant == 1 ? "09:30" : "14:45"
    when "datetime"
      variant == 1 ? "2024-03-15T09:30" : "2024-06-20T14:45"
    when "select"
      variant == 1 ? "Option A" : "Option B"
    when "currency"
      variant == 1 ? "29.99" : "149.00"
    when "colour"
      variant == 1 ? "#3b82f6" : "#ef4444"
    when "computed"
      variant == 1 ? "(calculated)" : "(calculated)"
    else
      variant == 1 ? "value" : "value"
    end
  end
end
