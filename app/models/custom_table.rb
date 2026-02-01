class CustomTable < ApplicationRecord
  RESERVED_SLUGS = %w[
    session sessions organisation_session edit_mode passwords organisations
    record-links up new reorder-tables rails manifests service-worker
  ].freeze

  belongs_to :organisation

  has_many :custom_fields, dependent: :destroy
  has_many :custom_records, dependent: :destroy
  has_many :source_relationships, class_name: "CustomRelationship", foreign_key: :source_table_id, dependent: :destroy
  has_many :target_relationships, class_name: "CustomRelationship", foreign_key: :target_table_id, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :organisation_id }
  validates :slug, presence: true, uniqueness: { scope: :organisation_id }
  validates :slug, exclusion: { in: RESERVED_SLUGS, message: "is reserved" }
  validate :name_must_be_plural

  before_validation :generate_slug

  def to_param
    slug
  end

  def all_relationships
    CustomRelationship.where(source_table_id: id).or(CustomRelationship.where(target_table_id: id))
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end

  def name_must_be_plural
    return if name.blank?
    errors.add(:name, "must be plural (e.g. \"#{name.pluralize}\")") unless name == name.pluralize
  end
end
