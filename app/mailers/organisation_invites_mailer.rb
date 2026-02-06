class OrganisationInvitesMailer < ApplicationMailer
  def invite(organisation_invite)
    @invite = organisation_invite
    @organisation = organisation_invite.organisation
    mail subject: "You've been invited to join #{@organisation.name}", to: @invite.email
  end
end
