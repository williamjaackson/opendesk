class DashboardController < ApplicationController
  def show
    unless Current.organisation
      redirect_to organisations_path
      return
    end

    first_table = Current.organisation.custom_tables.order(:position).first

    if first_table
      redirect_to table_path(first_table)
    end
  end
end
