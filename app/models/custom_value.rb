class CustomValue < ApplicationRecord
  belongs_to :custom_record
  belongs_to :custom_column

  validate :validate_value_format

  private

  def validate_value_format
    return unless value.present?

    case custom_column.column_type
    when "number"
      errors.add(:value, "must be a whole number") unless value.match?(/\A[0-9]+\z/)
    when "email"
      errors.add(:value, "must be a valid email address") unless value.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
    when "boolean"
      errors.add(:value, "must be yes or no") unless value.in?(%w[0 1])
    when "date"
      errors.add(:value, "must be a valid date") unless value.match?(/\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\z/)
    when "time"
      errors.add(:value, "must be a valid time in HH:MM format") unless value.match?(/\A([01]\d|2[0-3]):[0-5]\d\z/)
    when "datetime"
      errors.add(:value, "must be a valid date and time") unless value.match?(/\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):[0-5]\d\z/)
    when "select"
      errors.add(:value, "is not a valid option") unless custom_column.effective_options.include?(value)
    end

    if custom_column.column_type.in?(%w[text number]) && custom_column.regex_pattern.present?
      unless value.match?(Regexp.new(custom_column.regex_pattern))
        label = custom_column.regex_label.presence || "validation"
        errors.add(:value, "failed #{label} check")
      end
    end
  end
end
