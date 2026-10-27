class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  before_action :configure_sign_up, if: :devise_controller?

  def configure_sign_up
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :display_name ])
  end

  stale_when_importmap_changes
end
