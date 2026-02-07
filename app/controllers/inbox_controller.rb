class InboxController < ApplicationController
  def index
    @notifications = Current.user.notifications.recent.includes(:notifiable)

    # Preload organisations for invite notifications to avoid N+1
    invites = @notifications.filter_map { |n| n.notifiable if n.notifiable_type == "OrganisationInvite" }
    ActiveRecord::Associations::Preloader.new(records: invites, associations: :organisation).call if invites.any?
  end

  def accept
    @invite = OrganisationInvite.pending.find_by!(id: params[:id], email: Current.user.email_address)

    if @invite.accept!(Current.user)
      @invite.notification&.mark_as_read!
      redirect_to inbox_path, notice: "You've joined #{@invite.organisation.name}!"
    else
      redirect_to inbox_path, alert: "Unable to accept invitation."
    end
  end

  def decline
    @invite = OrganisationInvite.pending.find_by!(id: params[:id], email: Current.user.email_address)
    @invite.update!(declined_at: Time.current)
    @invite.notification&.mark_as_read!
    redirect_to inbox_path, notice: "Invitation declined."
  end
end
