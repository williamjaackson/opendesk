class CustomField < ApplicationRecord
  FIELD_TYPES = %w[text number date boolean select].freeze

  belongs_to :custom_table

  has_many :custom_values, dependent: :destroy

  validates :name, presence: true
  validates :field_type, presence: true, inclusion: { in: FIELD_TYPES }
end
