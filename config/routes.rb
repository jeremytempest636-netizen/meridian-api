Rails.application.routes.draw do
  get "up", to: "rails/health#show"

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"

      get "users/me", to: "users#me"
      get "users", to: "users#index"

      get "work_orders/overdue", to: "work_orders#overdue"

      resources :work_orders do
        resources :audit_events, only: [ :index ]
      end
    end
  end

  match "/api/*path", to: "api/v1/errors#not_found", via: :all
end
