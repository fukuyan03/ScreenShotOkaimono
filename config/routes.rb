Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  root "home#top"

  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

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
