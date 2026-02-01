class Organisation < ApplicationRecord
  has_many :organisation_users, dependent: :destroy
  has_many :users, through: :organisation_users
  has_many :table_groups, -> { order(:position) }, dependent: :destroy
  has_many :custom_tables, dependent: :destroy

  validates :name, presence: true

  after_create :create_default_table_group

  private

  def create_default_table_group
    table_groups.create!(name: "Tables", slug: "tables", position: 0)
  end
end
