Rails.application.routes.draw do
  devise_for :users, path_names: { sign_in: 'sign-in', sign_out: 'sign-out', sign_up: 'sign-up' }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "public#index"
  get "about", to: "public#about"
  mount_ember_app :frontend, to: "/app"
end
