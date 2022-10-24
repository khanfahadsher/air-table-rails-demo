Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "copy#index"
  #
  resources :copy, only: [:index] do
    collection do
      get :refresh
      get :bye
    end
  end

  get 'copy/:kind' => 'copy#show'
  # , :constraints => { :id => /[0-9A-Za-z\-\.]+/ }


end
