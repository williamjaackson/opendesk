class DashboardController < ApplicationController
  def show
    unless Current.organisation
      redirect_to organisations_path
      return
    end

    first_group = Current.organisation.table_groups.first
    redirect_to group_path(first_group)
  end
end
