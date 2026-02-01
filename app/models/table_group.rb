class TableGroup < ApplicationRecord
  belongs_to :organisation
  has_many :custom_tables, -> { order(:position) }, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :organisation_id }
  validates :slug, presence: true, uniqueness: { scope: :organisation_id }

  before_validation :generate_slug

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
