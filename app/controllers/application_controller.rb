class ApplicationController < ActionController::Base
  include Pagy::Method
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :builder_mode?

  private

  def builder_mode?
    session[:builder_mode] == true
  end

  def require_builder_mode
    @requires_builder_mode = true
    redirect_to root_path unless builder_mode?
  end
end
