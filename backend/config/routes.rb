Rails.application.routes.draw do
  namespace :api do
    # Authentication routes
    post "auth/register"
    post "auth/login"
    get "auth/me"
    
    # User routes
    resources :users, only: [:index, :show, :update] do
      member do
        post :follow
        delete :follow, action: :unfollow
        get :following
        get :followers
        get :documents
        get :creator_stats
      end
      
      collection do
        get :me
      end
    end
    
    # Document routes
    resources :documents do
      member do
        post :purchase
      end
      
      # Nested comment routes
      resources :comments, only: [:index, :create]
    end
    
    # Subscription routes
    resources :subscriptions do
      member do
        delete :cancel
        post :reactivate
      end
      
      collection do
        get :creator, action: :creator_subscriptions
      end
    end
    
    # Creator subscription info
    get 'creators/:creator_id/subscription_info', to: 'subscriptions#creator_info'
    
    # Transaction routes
    resources :transactions, only: [:index, :show] do
      member do
        post :refund
      end
      
      collection do
        get :sales
        get :analytics
      end
    end
    
    # Comment routes (for replies and actions)
    resources :comments, only: [:show, :update, :destroy] do
      member do
        post :vote
        post :report
      end
      
      # Nested replies
      resources :replies, controller: :comments, only: [:index, :create]
    end
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
