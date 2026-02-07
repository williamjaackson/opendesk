class UpdatePendingInvitesIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :organisation_invites, name: "index_pending_invites_on_org_and_email"
    add_index :organisation_invites, [ :organisation_id, :email ],
              unique: true,
              where: "accepted_at IS NULL AND declined_at IS NULL",
              name: "index_pending_invites_on_org_and_email"
  end
end
