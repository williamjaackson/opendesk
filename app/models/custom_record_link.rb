class CustomRecordLink < ApplicationRecord
  belongs_to :custom_relationship
  belongs_to :source_record, class_name: "CustomRecord"
  belongs_to :target_record, class_name: "CustomRecord"

  validates :target_record_id, uniqueness: { scope: [ :custom_relationship_id, :source_record_id ] }
  validate :enforce_cardinality, on: :create
  validate :prevent_self_link
  validate :records_match_relationship_tables
  validate :prevent_symmetric_duplicate

  private

  def prevent_self_link
    return if source_record_id.blank? || target_record_id.blank?
    errors.add(:base, "cannot link a record to itself") if source_record_id == target_record_id
  end

  def records_match_relationship_tables
    return unless custom_relationship && source_record && target_record
    errors.add(:source_record, "does not belong to the source table") unless source_record.custom_table_id == custom_relationship.source_table_id
    errors.add(:target_record, "does not belong to the target table") unless target_record.custom_table_id == custom_relationship.target_table_id
  end

  def prevent_symmetric_duplicate
    return unless custom_relationship&.symmetric?
    return if source_record_id.blank? || target_record_id.blank?

    if CustomRecordLink.where(
      custom_relationship: custom_relationship,
      source_record_id: target_record_id,
      target_record_id: source_record_id
    ).where.not(id: id).exists?
      errors.add(:base, "a symmetric link already exists between these records")
    end
  end

  def enforce_cardinality
    return unless custom_relationship

    case custom_relationship.kind
    when "one_to_one"
      if custom_relationship.symmetric?
        if CustomRecordLink.where(custom_relationship: custom_relationship)
            .where("source_record_id = :id OR target_record_id = :id", id: source_record_id)
            .where.not(id: id).exists?
          errors.add(:source_record, "already has a linked record in this relationship")
        end
        if CustomRecordLink.where(custom_relationship: custom_relationship)
            .where("source_record_id = :id OR target_record_id = :id", id: target_record_id)
            .where.not(id: id).exists?
          errors.add(:target_record, "already has a linked record in this relationship")
        end
      else
        if CustomRecordLink.where(custom_relationship: custom_relationship, source_record: source_record).where.not(id: id).exists?
          errors.add(:source_record, "already has a linked record in this relationship")
        end
        if CustomRecordLink.where(custom_relationship: custom_relationship, target_record: target_record).where.not(id: id).exists?
          errors.add(:target_record, "already has a linked record in this relationship")
        end
      end
    when "one_to_many"
      if CustomRecordLink.where(custom_relationship: custom_relationship, target_record: target_record).where.not(id: id).exists?
        errors.add(:target_record, "is already linked to another record in this relationship")
      end
    when "many_to_one"
      if CustomRecordLink.where(custom_relationship: custom_relationship, source_record: source_record).where.not(id: id).exists?
        errors.add(:source_record, "already has a linked record in this relationship")
      end
    end
  end
end
