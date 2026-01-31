class EditModesController < ApplicationController
  def update
    session[:edit_mode] = !session[:edit_mode]
    head :no_content
  end
end
