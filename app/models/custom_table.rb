class CustomTable < ApplicationRecord
  belongs_to :organisation
  belongs_to :table_group, optional: true

  has_many :custom_columns, dependent: :destroy
  has_many :custom_records, dependent: :destroy
  has_many :source_relationships, class_name: "CustomRelationship", foreign_key: :source_table_id, dependent: :destroy
  has_many :target_relationships, class_name: "CustomRelationship", foreign_key: :target_table_id, dependent: :destroy
  has_many :csv_imports, dependent: :destroy

  default_scope { where(deleted_at: nil) }

  validates :name, presence: true, uniqueness: { scope: :organisation_id }
  validates :slug, presence: true, uniqueness: { scope: :organisation_id }
  validate :name_must_be_plural

  before_validation :generate_slug

  def soft_delete!
    update_columns(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  def to_param
    slug
  end

  def all_relationships
    CustomRelationship.where(source_table_id: id).or(CustomRelationship.where(target_table_id: id)).order(:position)
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
