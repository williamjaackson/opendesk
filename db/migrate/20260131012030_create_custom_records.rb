class CreateCustomRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_records do |t|
      t.references :custom_table, null: false, foreign_key: true

      t.timestamps
    end
  end
end
