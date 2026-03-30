Rails.application.routes.draw do
  devise_for :users

  root "dashboard#index"

  resources :default_resumes, only: [ :show, :new, :create, :edit, :update ] do
    member do
      get :edit_markdown
      post :update_markdown
    end
  end

  resources :resumes, only: [ :index, :new, :create, :show ] do
    member do
      post :regenerate
    end

    resources :optimized_resumes, only: [ :edit, :update, :destroy ], shallow: true
  end
end
