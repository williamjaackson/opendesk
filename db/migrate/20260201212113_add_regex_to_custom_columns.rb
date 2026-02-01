class AddRegexToCustomColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_columns, :regex_pattern, :string
    add_column :custom_columns, :regex_label, :string
  end
end
