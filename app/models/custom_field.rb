class CustomField < ApplicationRecord
  FIELD_TYPES = %w[text number date boolean select].freeze

  belongs_to :custom_table

  has_many :custom_values, dependent: :destroy

  validates :name, presence: true
  validates :field_type, presence: true, inclusion: { in: FIELD_TYPES }

  after_destroy :cleanup_empty_records

  private

  def cleanup_empty_records
    custom_table.custom_records.left_joins(:custom_values).where(custom_values: { id: nil }).destroy_all
  end
end
