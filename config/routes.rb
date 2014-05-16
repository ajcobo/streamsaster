Streamsaster::Application.routes.draw do
  resources :custom_tweets


  resources :tweets


  authenticated :user do
    root :to => 'home#index'
  end
  root :to => "home#index"
  devise_for :users
  resources :users
end