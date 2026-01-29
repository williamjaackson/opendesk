class OrganisationsController < ApplicationController
  def index
    @organisations = Current.user.organisations
  end
end
