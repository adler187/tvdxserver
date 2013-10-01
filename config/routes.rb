Tvscanner::Application.routes.draw do
#   map.resources :time_intervals, :collection => { :sort => :post }
#   map.resources :logs
#   map.resources :tuners, :collection => { :sort => :post }
#   map.resources :stations, :collection => { :destroy_all => :delete }
#   map.resources :admin
#   map.resources :home
# 
#   map.chart 'chart/:station_id/:tuner_id', :controller => 'chart', :action => 'index'
# 
#   map.root :controller => 'home'
  
  resources :time_intervals do
    collection do
      post :sort
    end
  end
  
  resources :tuners do
    collection do
      post :sort
    end
  end
  
  match "/tuners/:tuner_id/:tuner_number" => "tuners#show", :constraints => { :tuner_id => /[a-fA-F0-9]+/, :tuner_number => /\d+/ }
  
  resources :stations do
    collection do
      delete :destroy_all
    end
  end
  
  resources :logs
  resources :admin
  resources :home

  match "/chart/:station_id/:tuner_id" => 'chart#index', :as => :chart
  
  root :to => 'home#index'
end
