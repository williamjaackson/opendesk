class OrganisationUser < ApplicationRecord
  ROLES = %w[admin member].freeze

  belongs_to :organisation
  belongs_to :user

  validates :role, presence: true, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end
end
