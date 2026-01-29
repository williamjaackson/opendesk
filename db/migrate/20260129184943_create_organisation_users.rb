class CreateOrganisationUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :organisation_users do |t|
      t.references :organisation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
