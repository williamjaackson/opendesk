class AddThemeColourToOrganisations < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :theme_colour, :string
  end
end
