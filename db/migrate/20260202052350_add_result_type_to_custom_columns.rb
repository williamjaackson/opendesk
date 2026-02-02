class AddResultTypeToCustomColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_columns, :result_type, :string
  end
end
