Rails.application.routes.draw do
  resource :session
  resource :organisation_session, only: [ :create, :destroy ]
  resource :builder_mode, only: [ :update ]
  resources :passwords, param: :token
  resources :organisations, only: [ :index, :new, :create, :show, :edit, :update, :destroy ]
  resources :custom_record_links, path: "record-links", as: :record_links, only: [ :create, :destroy ]

  # Table groups
  resources :table_groups, path: "groups", as: :groups, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      patch :add_table
    end
    collection do
      patch :reorder
    end
  end

  # Table routes under /t/
  scope "/t" do
    get "/new", to: "custom_tables#new", as: :new_table
    post "/", to: "custom_tables#create", as: :tables
    patch "/reorder-tables", to: "custom_tables#reorder", as: :reorder_tables

    resources :custom_tables, path: "/", param: :slug, as: :table, only: [ :show, :edit, :update, :destroy ] do
      member do
        patch :toggle_protection
        get :export
        get :template
      end
      resources :custom_columns, path: "columns", as: :columns, only: [ :new, :create, :edit, :update, :destroy ] do
        collection do
          patch :reorder
          get :backfill_select_options
        end
      end
      resources :custom_relationships, path: "relationships", as: :relationships, only: [ :new, :create, :edit, :update, :destroy ] do
        collection do
          patch :reorder
        end
      end
      resources :csv_imports, path: "imports", as: :csv_imports, only: [ :new, :create, :show, :update, :destroy ]

      # Records at table root, numeric IDs only
      resources :custom_records, path: "/", as: :records, only: [ :new, :create, :show, :edit, :update, :destroy ],
        constraints: { id: /\d+/ }
    end
  end

  get "docs/formulas", to: "pages#formulas", as: :formulas_docs

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  authenticated = ->(req) { req.cookie_jar.signed[:session_id].present? && Session.exists?(req.cookie_jar.signed[:session_id]) }

  constraints(authenticated) do
    root "dashboard#show", as: :authenticated_root
  end
  root "pages#landing"
end
