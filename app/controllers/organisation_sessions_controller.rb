class OrganisationSessionsController < ApplicationController
  def create
    organisation = Current.user.organisations.find(params[:organisation_id])
    session[:organisation_id] = organisation.id
    redirect_to root_path
  end

  def destroy
    organisation = Current.organisation
    session.delete(:organisation_id)
    redirect_to organisation_path(organisation)
  end
end
