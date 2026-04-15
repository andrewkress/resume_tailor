Rails.application.routes.draw do
  devise_for :users

  root "dashboard#index"

  resource :profile, only: [ :edit, :update ]

  resources :resumes, only: [ :index, :new, :create, :show, :destroy ] do
    member do
      post :regenerate
    end

    resources :optimized_resumes, only: [ :edit, :update, :destroy ], shallow: true
  end
end
