Spree::Core::Engine.routes.draw do

  resources :loyalty_points, only: [:index]

  namespace :admin do
    resources :users do
      resources :loyalty_points, only: [:index, :new, :create], controller: 'loyalty_points_transactions' do
        get 'order_transactions/:order_id', action: :order_transactions, on: :collection
      end
    end
  end
  
  namespace :admin do
    resources :users, only: [] do
      resources :store_credits

      collection do
        resources :gift_cards, only: [:index, :show]
      end
    end
  end

  namespace :api, defaults: { format: 'json' } do
    resources :store_credit_events, only: [] do
      collection do
        get :mine
      end
    end

    resources :gift_cards, only: [] do
      collection do
        post :redeem
      end
    end
  end
end
