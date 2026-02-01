class AddOptionsToCustomColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_columns, :options, :json
  end
end
