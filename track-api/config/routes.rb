Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :users, :only => [:create] do
    resources :songs, only: [:index, :show]
  end
  resources :sessions, :only => [:create, :destroy]

  get '/songs', to: 'songs#index'
  post '/songs', to: 'songs#create'
  get '/get_song', to: 'songs#get_song'
end
