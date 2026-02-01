class CustomColumn < ApplicationRecord
  COLUMN_TYPES = %w[text number email boolean date time datetime select].freeze

  belongs_to :custom_table

  has_many :custom_values, dependent: :destroy

  validates :name, presence: true
  validates :column_type, presence: true, inclusion: { in: COLUMN_TYPES, allow_blank: true }
  validate :validate_select_options

  after_destroy :cleanup_empty_records

  def options_text
    (options || []).join("\n")
  end

  def options_text=(text)
    self.options = text.to_s.split("\n").map(&:strip).reject(&:blank?)
  end

  private

  def validate_select_options
    return unless column_type == "select"

    if options.blank? || !options.is_a?(Array) || options.empty?
      errors.add(:options, "must have at least one option")
    end
  end

  def cleanup_empty_records
    custom_table.custom_records.left_joins(:custom_values).where(custom_values: { id: nil }).destroy_all
  end
end
