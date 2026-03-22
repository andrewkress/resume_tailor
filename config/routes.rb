Rails.application.routes.draw do
  devise_for :users

  root "dashboard#index"

  resources :resumes, only: [ :index, :new, :create, :show ] do
    resources :optimized_resumes, only: [ :show ]
  end
end
