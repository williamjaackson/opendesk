class BuilderModesController < ApplicationController
  def update
    session[:builder_mode] = !session[:builder_mode]
    head :no_content
  end
end
