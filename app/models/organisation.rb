class Organisation < ApplicationRecord
  has_many :organisation_users, dependent: :destroy
  has_many :users, through: :organisation_users
end
