Rails.application.routes.draw do
  resources :users do
    post 'bind', to: "users#bind"
  end

  resources :hackathons
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
