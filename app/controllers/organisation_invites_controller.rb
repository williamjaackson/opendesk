class OrganisationInvitesController < ApplicationController
  allow_unauthenticated_access only: [ :show ]
  before_action :set_invite, only: [ :show, :destroy ]

  def create
    @organisation = Current.user.organisations.find(params[:organisation_id])
    @membership = @organisation.organisation_users.find_by(user: Current.user)

    unless @membership&.admin?
      redirect_to members_organisation_path(@organisation), alert: "You must be an admin to invite members."
      return
    end

    @invite = @organisation.organisation_invites.new(invite_params)

    if @organisation.users.exists?(email_address: @invite.email)
      redirect_to members_organisation_path(@organisation), alert: "This person is already a member."
      return
    end

    if @invite.save
      OrganisationInvitesMailer.invite(@invite).deliver_later
      redirect_to members_organisation_path(@organisation), notice: "Invitation sent to #{@invite.email}."
    else
      redirect_to members_organisation_path(@organisation), alert: @invite.errors.full_messages.first
    end
  end

  def show
    if @invite.accepted?
      redirect_to root_path, alert: "This invitation has already been accepted."
      return
    end

    if authenticated?
      if Current.user.email_address == @invite.email
        # Auto-accept if logged in with matching email
        if @invite.accept!(Current.user)
          redirect_to organisation_path(@invite.organisation), notice: "You've joined #{@invite.organisation.name}!"
        else
          redirect_to root_path, alert: "Unable to accept invitation."
        end
      else
        # Logged in but different email - must sign out first
        @email_mismatch = true
      end
    else
      # Not logged in - store token and show sign in/up options
      session[:pending_invite_token] = @invite.token
    end
  end

  def destroy
    @organisation = Current.user.organisations.find(@invite.organisation_id)
    @membership = @organisation.organisation_users.find_by(user: Current.user)

    unless @membership&.admin?
      redirect_to members_organisation_path(@organisation), alert: "You must be an admin to cancel invitations."
      return
    end

    @invite.destroy
    redirect_to members_organisation_path(@organisation), notice: "Invitation cancelled."
  end

  private

  def set_invite
    @invite = OrganisationInvite.find_by!(token: params[:token])
  end

  def invite_params
    params.require(:organisation_invite).permit(:email)
  end
end
