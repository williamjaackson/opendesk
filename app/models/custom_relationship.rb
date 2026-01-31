class CustomRelationship < ApplicationRecord
  KINDS = %w[has_one has_many many_to_many].freeze

  belongs_to :source_table, class_name: "CustomTable"
  belongs_to :target_table, class_name: "CustomTable"

  has_many :custom_record_links, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :source_table_id }
  validates :inverse_name, presence: true, uniqueness: { scope: :target_table_id }
  validates :kind, presence: true, inclusion: { in: KINDS }
  validate :tables_belong_to_same_organisation

  private

  def tables_belong_to_same_organisation
    return unless source_table && target_table
    errors.add(:base, "Tables must belong to the same organisation") unless source_table.organisation_id == target_table.organisation_id
  end
end
