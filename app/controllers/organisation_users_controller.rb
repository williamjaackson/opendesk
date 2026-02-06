class OrganisationUsersController < ApplicationController
  def destroy
    @organisation = Current.user.organisations.find(params[:organisation_id])
    @membership = @organisation.organisation_users.find(params[:id])

    if @membership.user == Current.user
      redirect_to members_organisation_path(@organisation), alert: "You cannot remove yourself."
      return
    end

    @membership.destroy
    redirect_to members_organisation_path(@organisation), notice: "Member removed."
  end
end
