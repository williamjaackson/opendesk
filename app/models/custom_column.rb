class CustomColumn < ApplicationRecord
  COLUMN_TYPES = %w[text number email boolean].freeze

  belongs_to :custom_table

  has_many :custom_values, dependent: :destroy

  validates :name, presence: true
  validates :column_type, presence: true, inclusion: { in: COLUMN_TYPES, allow_blank: true }

  after_destroy :cleanup_empty_records

  private

  def cleanup_empty_records
    custom_table.custom_records.left_joins(:custom_values).where(custom_values: { id: nil }).destroy_all
  end
end
