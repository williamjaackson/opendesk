class CustomColumn < ApplicationRecord
  COLUMN_TYPES = %w[text number decimal email boolean date time datetime select currency colour computed].freeze

  belongs_to :custom_table
  belongs_to :linked_column, class_name: "CustomColumn", optional: true

  has_many :linking_columns, class_name: "CustomColumn", foreign_key: :linked_column_id, dependent: :nullify
  has_many :custom_values, dependent: :destroy

  validates :name, presence: true
  validates :column_type, presence: true, inclusion: { in: COLUMN_TYPES, allow_blank: true }
  validate :validate_select_options
  validate :validate_regex_pattern
  validate :validate_computed_formula

  before_validation :clear_options_for_linked_select
  before_validation :clear_regex_for_non_applicable_types
  before_validation :clear_computed_constraints

  after_destroy :cleanup_empty_records

  def effective_options
    if linked_column_id.present?
      CustomValue.where(custom_column: linked_column).where.not(value: [ nil, "" ]).distinct.pluck(:value).sort
    else
      options || []
    end
  end

  def select_source
    @select_source || (linked_column_id.present? ? "linked" : "manual")
  end

  def select_source=(value)
    @select_source = value
  end

  def linked_table_id
    linked_column&.custom_table_id
  end

  def options_text
    (options || []).join("\n")
  end

  def options_text=(text)
    self.options = text.to_s.split("\n").map(&:strip).reject(&:blank?)
  end

  def computed?
    column_type == "computed"
  end

  private

  def clear_options_for_linked_select
    return unless column_type == "select"

    if select_source == "linked"
      self.options = nil
    else
      self.linked_column_id = nil
    end
  end

  def validate_select_options
    return unless column_type == "select"

    if select_source == "linked"
      if linked_column_id.blank?
        errors.add(:linked_column_id, "must be selected")
      elsif linked_column.nil?
        errors.add(:linked_column_id, "is invalid")
      elsif linked_column.custom_table.organisation_id != custom_table.organisation_id
        errors.add(:linked_column_id, "must belong to the same organisation")
      end
    else
      if options.blank? || !options.is_a?(Array) || options.empty?
        errors.add(:options_text, "must have at least one option")
      end
    end
  end

  def clear_regex_for_non_applicable_types
    unless column_type.in?(%w[text number decimal])
      self.regex_pattern = nil
      self.regex_label = nil
    end
  end

  def validate_regex_pattern
    return if regex_pattern.blank? && regex_label.blank?

    unless column_type.in?(%w[text number decimal])
      errors.add(:regex_pattern, "is only allowed on text, number, or decimal columns") if regex_pattern.present?
      return
    end

    if regex_pattern.blank?
      errors.add(:regex_pattern, "can't be blank")
    else
      begin
        Regexp.new(regex_pattern)
      rescue RegexpError
        errors.add(:regex_pattern, "is not a valid regular expression")
      end
    end

    if regex_label.blank?
      errors.add(:regex_label, "can't be blank")
    end
  end

  def clear_computed_constraints
    return unless computed?

    self.required = false
    self.regex_pattern = nil
    self.regex_label = nil
    self.options = nil
    self.linked_column_id = nil
  end

  def validate_computed_formula
    if computed?
      errors.add(:formula, "can't be blank") if formula.blank?
    else
      errors.add(:formula, "is only allowed on computed columns") if formula.present?
    end
  end

  def cleanup_empty_records
    custom_table.custom_records.left_joins(:custom_values).where(custom_values: { id: nil }).destroy_all
  end
end
