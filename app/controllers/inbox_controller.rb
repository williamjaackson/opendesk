class InboxController < ApplicationController
  def index
    @invites = OrganisationInvite.where(email: Current.user.email_address)
                                 .includes(:organisation)
                                 .order(created_at: :desc)
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
    @invite.update!(declined_at: Time.current)
    redirect_to inbox_path, notice: "Invitation declined."
  end
end
