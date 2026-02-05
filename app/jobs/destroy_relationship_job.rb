class DestroyRelationshipJob < ApplicationJob
  queue_as :default

  def perform(custom_relationship_id)
    custom_relationship = CustomRelationship.find(custom_relationship_id)

    # 1. Delete all record links in batches
    custom_relationship.custom_record_links.in_batches(of: 1000).delete_all

    # 2. Delete the relationship itself
    custom_relationship.delete
  rescue ActiveRecord::RecordNotFound
    # Relationship was already deleted
  end
end
