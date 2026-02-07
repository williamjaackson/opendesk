class AddDeclinedAtToOrganisationInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :organisation_invites, :declined_at, :datetime
  end
end
