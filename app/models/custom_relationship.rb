class CustomRelationship < ApplicationRecord
  KINDS = %w[one_to_one one_to_many many_to_one many_to_many].freeze

  belongs_to :source_table, class_name: "CustomTable"
  belongs_to :target_table, class_name: "CustomTable"

  has_many :custom_record_links, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :source_table_id }
  validates :inverse_name, presence: true, uniqueness: { scope: :target_table_id }
  validates :kind, presence: true, inclusion: { in: KINDS }
  validate :tables_belong_to_same_organisation
  validate :symmetric_requires_self_referential
  validate :symmetric_not_allowed_on_has_many

  before_validation :auto_set_symmetric
  before_validation :mirror_inverse_name_if_symmetric

  def self_referential?
    source_table_id == target_table_id
  end

  private

  def auto_set_symmetric
    if self_referential? && kind == "one_to_one"
      self.symmetric = true
    end
  end

  def mirror_inverse_name_if_symmetric
    if symmetric?
      self.inverse_name = name
    end
  end

  def symmetric_requires_self_referential
    if symmetric? && !self_referential?
      errors.add(:symmetric, "is only allowed on self-referential relationships")
    end
  end

  def symmetric_not_allowed_on_has_many
    if symmetric? && %w[one_to_many many_to_one].include?(kind)
      errors.add(:symmetric, "is not allowed on one-to-many or many-to-one relationships")
    end
  end

  def tables_belong_to_same_organisation
    return unless source_table && target_table
    errors.add(:base, "Tables must belong to the same organisation") unless source_table.organisation_id == target_table.organisation_id
  end
end
