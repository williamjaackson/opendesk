class DashboardController < ApplicationController
  def show
    first_table = Current.organisation&.custom_tables&.order(:position)&.first

    if first_table
      redirect_to custom_table_path(first_table)
    end
  end
end
