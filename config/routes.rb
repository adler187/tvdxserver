Tvscanner::Application.routes.draw do |map|
  map.resources :time_intervals, :collection => { :sort => :post }
  map.resources :logs
  map.resources :tuners, :collection => { :sort => :post }
  map.resources :stations, :collection => { :destroy_all => :delete }
  map.resources :admin
  map.resources :home

  map.chart 'chart/:station_id/:tuner_id', :controller => 'chart', :action => 'index'

  map.root :controller => 'home'
end
