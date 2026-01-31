Rails.application.routes.draw do
  resource :session
  resource :organisation_session, only: [ :create, :destroy ]
  resources :passwords, param: :token
  resources :organisations, only: [ :index, :new, :create, :show ]
  resources :custom_tables, only: [ :new, :create, :show ]
  get "dashboard", to: "dashboard#show", as: :dashboard

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  authenticated = ->(req) { req.cookie_jar.signed[:session_id].present? && Session.exists?(req.cookie_jar.signed[:session_id]) }

  constraints(authenticated) do
    root "organisations#index", as: :authenticated_root
  end
  root "pages#landing"
end
