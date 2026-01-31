class CustomTable < ApplicationRecord
  belongs_to :organisation

  has_many :custom_fields, dependent: :destroy
  has_many :custom_records, dependent: :destroy
  has_many :source_relationships, class_name: "CustomRelationship", foreign_key: :source_table_id, dependent: :destroy
  has_many :target_relationships, class_name: "CustomRelationship", foreign_key: :target_table_id, dependent: :destroy

  validates :name, presence: true
  validate :name_must_be_plural

  def all_relationships
    CustomRelationship.where(source_table_id: id).or(CustomRelationship.where(target_table_id: id))
  end

  private

  def name_must_be_plural
    return if name.blank?
    errors.add(:name, "must be plural (e.g. \"#{name.pluralize}\")") unless name == name.pluralize
  end
end
