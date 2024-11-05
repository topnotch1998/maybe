Rails.application.routes.draw do
  mount GoodJob::Engine => "good_job"

  get "changelog", to: "pages#changelog"
  get "feedback", to: "pages#feedback"
  get "early-access", to: "pages#early_access"

  resource :registration, only: %i[new create]
  resources :sessions, only: %i[new create destroy]
  resource :password_reset, only: %i[new create edit update]
  resource :password, only: %i[edit update]

  resources :users, only: %i[update destroy]

  resource :onboarding, only: :show do
    collection do
      get :profile
      get :preferences
    end
  end

  namespace :settings do
    resource :profile, only: :show
    resource :preferences, only: :show
    resource :hosting, only: %i[show update]
    resource :billing, only: :show
  end

  resource :subscription, only: %i[new show] do
    get :success, on: :collection
  end

  resources :tags, except: :show do
    resources :deletions, only: %i[new create], module: :tag
  end

  namespace :category do
    resource :dropdown, only: :show
  end

  resources :categories do
    resources :deletions, only: %i[new create], module: :category
  end

  resources :merchants, only: %i[index new create edit update destroy]

  namespace :account do
    resources :transfers, only: %i[new create destroy show update]
  end

  resources :imports, only: %i[index new show create destroy] do
    post :publish, on: :member

    resource :upload, only: %i[show update], module: :import
    resource :configuration, only: %i[show update], module: :import
    resource :clean, only: :show, module: :import
    resource :confirm, only: :show, module: :import

    resources :rows, only: %i[show update], module: :import
    resources :mappings, only: :update, module: :import
  end

  resources :accounts, only: %i[index new] do
    collection do
      get :summary
      get :list
      post :sync_all
    end

    member do
      post :sync
    end

    scope module: :account do
      resources :holdings, only: %i[index new show destroy]
      resources :cashes, only: :index

      resources :transactions, only: %i[index update]
      resources :valuations, only: %i[index new create]
      resources :trades, only: %i[index new create update] do
        get :securities, on: :collection
      end

      resources :entries, only: %i[index edit update show destroy]
    end
  end

  # Convenience routes for polymorphic paths
  # Example: account_path(Account.new(accountable: Depository.new)) => /depositories/123
  direct :account do |model, options|
    route_for model.accountable_name, model, options
  end
  direct :edit_account do |model, options|
    route_for "edit_#{model.accountable_name}", model, options
  end

  resources :depositories, except: :index
  resources :investments, except: :index
  resources :properties, except: :index
  resources :vehicles, except: :index
  resources :credit_cards, except: :index
  resources :loans, except: :index
  resources :cryptos, except: :index
  resources :other_assets, except: :index
  resources :other_liabilities, except: :index

  resources :transactions, only: %i[index new create] do
    collection do
      post "bulk_delete"
      get "bulk_edit"
      post "bulk_update"
      post "mark_transfers"
      post "unmark_transfers"
    end
  end

  resources :institutions, except: %i[index show] do
    post :sync, on: :member
  end
  resources :invite_codes, only: %i[index create]

  resources :issues, only: :show

  namespace :issue do
    resources :exchange_rate_provider_missings, only: :update
  end

  resources :invitations, only: [ :new, :create ] do
    get :accept, on: :member
  end

  # For managing self-hosted upgrades and release notifications
  resources :upgrades, only: [] do
    member do
      post :acknowledge
      post :deploy
    end
  end

  resources :currencies, only: %i[show]

  resources :impersonation_sessions, only: [ :create ] do
    post :join, on: :collection
    delete :leave, on: :collection

    member do
      put :approve
      put :reject
      put :complete
    end
  end

  # Stripe webhook endpoint
  post "webhooks/stripe", to: "webhooks#stripe"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "pages#dashboard"
end
