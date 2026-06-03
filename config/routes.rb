Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  root "home#top"
  get "/terms", to: "pages#terms"
  get "/privacy", to: "pages#privacy"

  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  match "/auth/:provider/callback", to: "sessions#omniauth", via: %i[get post]
  match "/auth/failure", to: "sessions#failure", via: %i[get post]

  resource :password, only: %i[new create edit update]
  resources :users, only: %i[new create show]
  resources :shops, only: %i[index show new create edit update destroy] do
    resources :items, only: %i[index new show create edit update destroy] do
      collection do
        post :analyze
      end

      member do
        patch :update_status
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
