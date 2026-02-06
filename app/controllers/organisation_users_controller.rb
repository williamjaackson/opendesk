class OrganisationUsersController < ApplicationController
  before_action :set_organisation
  before_action :set_membership, only: [ :update, :destroy ]
  before_action :require_admin

  def update
    if @membership.user == Current.user
      redirect_to members_organisation_path(@organisation), alert: "You cannot change your own role."
      return
    end

    if @membership.update(role: params[:role])
      redirect_to members_organisation_path(@organisation), notice: "Role updated."
    else
      redirect_to members_organisation_path(@organisation), alert: "Could not update role."
    end
  end

  def destroy
    if @membership.user == Current.user
      redirect_to members_organisation_path(@organisation), alert: "You cannot remove yourself."
      return
    end

    @membership.destroy
    redirect_to members_organisation_path(@organisation), notice: "Member removed."
  end

  private

  def set_organisation
    @organisation = Current.user.organisations.find(params[:organisation_id])
  end

  def set_membership
    @membership = @organisation.organisation_users.find(params[:id])
  end

  def require_admin
    current_membership = @organisation.organisation_users.find_by(user: Current.user)
    unless current_membership&.admin?
      redirect_to members_organisation_path(@organisation), alert: "You must be an admin to do that."
    end
  end
end
