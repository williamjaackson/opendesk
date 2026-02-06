class CreateOrganisationInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :organisation_invites do |t|
      t.references :organisation, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :accepted_at

      t.timestamps
    end
    add_index :organisation_invites, :token, unique: true
    add_index :organisation_invites, [:organisation_id, :email], unique: true
  end
end
