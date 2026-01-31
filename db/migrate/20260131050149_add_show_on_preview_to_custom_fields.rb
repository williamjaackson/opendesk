class AddShowOnPreviewToCustomFields < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_fields, :show_on_preview, :boolean, default: true
  end
end
