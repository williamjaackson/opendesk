class CustomRecord < ApplicationRecord
  belongs_to :custom_table

  has_many :custom_values, dependent: :destroy
  has_many :source_record_links, class_name: "CustomRecordLink", foreign_key: :source_record_id, dependent: :destroy
  has_many :target_record_links, class_name: "CustomRecordLink", foreign_key: :target_record_id, dependent: :destroy

  def linked_records_for(relationship)
    if relationship.symmetric?
      source_ids = CustomRecordLink.where(custom_relationship: relationship, source_record: self).select(:target_record_id)
      target_ids = CustomRecordLink.where(custom_relationship: relationship, target_record: self).select(:source_record_id)
      CustomRecord.where(id: source_ids).or(CustomRecord.where(id: target_ids))
    elsif relationship.source_table_id == custom_table_id
      CustomRecord.where(id: CustomRecordLink.where(custom_relationship: relationship, source_record: self).select(:target_record_id))
    else
      CustomRecord.where(id: CustomRecordLink.where(custom_relationship: relationship, target_record: self).select(:source_record_id))
    end
  end

  def display_name
    ordered_values = custom_values.joins(:custom_column).merge(CustomColumn.order(:position))
    first_non_blank = ordered_values.find { |v| v.value.present? }
    first_non_blank&.value || "Record ##{id}"
  end
end
