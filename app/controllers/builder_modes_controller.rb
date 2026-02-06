class BuilderModesController < ApplicationController
  def update
    unless current_membership&.admin?
      head :forbidden
      return
    end

    session[:builder_mode] = !session[:builder_mode]
    head :no_content
  end

  private

  def current_membership
    return unless Current.organisation

    Current.organisation.organisation_users.find_by(user: Current.user)
  end
end
