class CreateCustomTables < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_tables do |t|
      t.references :organisation, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
