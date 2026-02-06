module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
    helper_method :managing_organisation?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
      resume_organisation_session if Current.session
      Current.session
    end

    def resume_organisation_session
      if session[:organisation_id].present?
        Current.organisation = Current.user.organisations.find_by(id: session[:organisation_id])
        session.delete(:organisation_id) unless Current.organisation
      end
    end

    def managing_organisation?
      Current.organisation.present?
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      # Redirect to pending invite if exists
      if (token = session[:pending_invite_token])
        invite = OrganisationInvite.find_by(token: token)
        if invite && !invite.accepted?
          return organisation_invite_url(invite.token)
        end
        session.delete(:pending_invite_token)
      end

      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
      # Preserve invite token across sign-out
      invite_token = session[:pending_invite_token]
      session.delete(:organisation_id)
      session[:pending_invite_token] = invite_token if invite_token
    end
end
