class InboxController < ApplicationController
  def index
    @invites = OrganisationInvite.pending.where(email: Current.user.email_address).includes(:organisation)
  end

  def accept
    @invite = OrganisationInvite.pending.find_by!(id: params[:id], email: Current.user.email_address)

    if @invite.accept!(Current.user)
      redirect_to inbox_path, notice: "You've joined #{@invite.organisation.name}!"
    else
      redirect_to inbox_path, alert: "Unable to accept invitation."
    end
  end

  def decline
    @invite = OrganisationInvite.pending.find_by!(id: params[:id], email: Current.user.email_address)
    @invite.destroy
    redirect_to inbox_path, notice: "Invitation declined."
  end
end
