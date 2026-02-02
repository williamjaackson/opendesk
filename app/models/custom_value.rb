class CustomValue < ApplicationRecord
  belongs_to :custom_record
  belongs_to :custom_column

  validate :validate_value_format

  private

  def validate_value_format
    return unless value.present?
    return if custom_column.computed?

    case custom_column.column_type
    when "number"
      errors.add(:value, "must be a whole number") unless value.match?(/\A[0-9]+\z/)
    when "decimal"
      errors.add(:value, "must be a number") unless value.match?(/\A\d+(\.\d+)?\z/)
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
    when "currency"
      errors.add(:value, "must be a valid dollar amount") unless value.match?(/\A\d+\.\d{2}\z/)
    when "colour"
      errors.add(:value, "must be a valid hex colour (e.g. #ff0000)") unless value.match?(/\A#[0-9a-fA-F]{6}\z/)
    end

    if custom_column.column_type.in?(%w[text number decimal]) && custom_column.regex_pattern.present?
      begin
        unless value.match?(Regexp.new(custom_column.regex_pattern, timeout: 1))
          label = custom_column.regex_label.presence || "validation"
          errors.add(:value, "failed #{label} check")
        end
      rescue Regexp::TimeoutError
        errors.add(:value, "validation timed out")
      end
    end
  end
end
