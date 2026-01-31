class CustomTable < ApplicationRecord
  belongs_to :organisation

  has_many :custom_fields, dependent: :destroy
  has_many :custom_records, dependent: :destroy
end
