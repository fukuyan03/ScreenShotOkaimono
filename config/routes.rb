Rails.application.routes.draw do
  root "home#top"

  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :users, only: %i[new create show]
  resources :shops, only: %i[index new create edit update destroy] do
    resources :items, only: %i[index new show create edit update destroy] do
      collection do
        post :analyze
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
