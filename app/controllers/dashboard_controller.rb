class DashboardController < ApplicationController
  def show
    unless Current.organisation
      redirect_to organisations_path
      return
    end

    first_group = Current.organisation.table_groups.first
    first_table = first_group&.custom_tables&.first

    if first_table
      redirect_to table_path(first_table)
    end
  end
end
