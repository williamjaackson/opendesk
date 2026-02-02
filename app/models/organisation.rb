class Organisation < ApplicationRecord
  has_many :organisation_users, dependent: :destroy
  has_many :users, through: :organisation_users
  has_many :custom_tables, dependent: :destroy
  has_many :table_groups, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true
  validates :theme_colour, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a valid hex colour (e.g. #2563eb)" }, allow_blank: true

  before_save :normalize_theme_colour
  after_create :create_default_table_group

  private

  def normalize_theme_colour
    self.theme_colour = nil if theme_colour.blank? || theme_colour == "#111827"
  end

  def create_default_table_group
    table_groups.create!(name: "Tables", slug: "tables", position: 0)
  end
end
