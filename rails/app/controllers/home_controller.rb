class HomeController < ApplicationController
	def index
		p params
		
		tuner_params = params[:tuner]
		@tuner = tuner_params.nil? ? Tuner.first : Tuner.find(tuner_params[:id])
		@logs = @tuner.logs
# 		if params[:location].nil?
			@map_location = { 'latitude' => SCAN_CONFIG['latitude'], 'longitude' => SCAN_CONFIG['longitude'] }
# 		else
# 			@map_location = params[:location]
# 		end
		

# 		if params[:zoom].nil?
# 			@zoom = params[:zoom]
# 		else
			@zoom = 8
# 		end
	end
end
