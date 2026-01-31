class CustomRecord < ApplicationRecord
  belongs_to :custom_table

  has_many :custom_values, dependent: :destroy
end
