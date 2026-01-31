class CustomRecordLink < ApplicationRecord
  belongs_to :custom_relationship
  belongs_to :source_record, class_name: "CustomRecord"
  belongs_to :target_record, class_name: "CustomRecord"

  validates :target_record_id, uniqueness: { scope: [ :custom_relationship_id, :source_record_id ] }
  validate :enforce_cardinality, on: :create

  private

  def enforce_cardinality
    return unless custom_relationship

    case custom_relationship.kind
    when "has_one"
      if CustomRecordLink.where(custom_relationship: custom_relationship, source_record: source_record).where.not(id: id).exists?
        errors.add(:source_record, "already has a linked record in this relationship")
      end
      if CustomRecordLink.where(custom_relationship: custom_relationship, target_record: target_record).where.not(id: id).exists?
        errors.add(:target_record, "already has a linked record in this relationship")
      end
    when "has_many"
      if CustomRecordLink.where(custom_relationship: custom_relationship, target_record: target_record).where.not(id: id).exists?
        errors.add(:target_record, "is already linked to another record in this relationship")
      end
    end
  end
end
