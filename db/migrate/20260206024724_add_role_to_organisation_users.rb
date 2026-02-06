class AddRoleToOrganisationUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :organisation_users, :role, :string, null: false, default: "member"

    # Make existing members admins (they were the original creators)
    reversible do |dir|
      dir.up do
        execute "UPDATE organisation_users SET role = 'admin'"
      end
    end
  end
end
