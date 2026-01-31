class EditModesController < ApplicationController
  def update
    session[:edit_mode] = !session[:edit_mode]
    redirect_back fallback_location: root_path
  end
end
