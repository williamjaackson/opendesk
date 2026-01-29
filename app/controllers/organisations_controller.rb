class OrganisationsController < ApplicationController
  def index
    @organisations = Current.user.organisations
  end

  def new
    @organisation = Organisation.new
  end

  def create
    @organisation = Organisation.new(organisation_params)

    if @organisation.save
      @organisation.users << Current.user
      redirect_to organisations_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def organisation_params
    params.require(:organisation).permit(:name)
  end
end
