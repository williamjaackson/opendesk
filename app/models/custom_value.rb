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
    end
  end
end
