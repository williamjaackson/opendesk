class AddFormulaToCustomColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_columns, :formula, :text
  end
end
