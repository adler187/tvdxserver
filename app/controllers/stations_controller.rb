class StationsController < ApplicationController
	
  before_filter :authenticate
  
  make_resourceful do
    actions :all
  end

  def destroy_all
    Station.destroy_all
	  
    redirect_to(stations_url)
  end
end
