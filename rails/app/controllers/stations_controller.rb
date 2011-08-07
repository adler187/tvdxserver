class StationsController < ApplicationController
	
  before_filter :authenticate
  
  make_resourceful do
    actions :all
  end

  def destroy_all
	  Station.all.each do |station|
		  station.destroy
	  end
	  
	  respond_to do |format|
		format.html { redirect_to(stations_url) }
		format.xml  { head :ok }
	  end
  end
end
