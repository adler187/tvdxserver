class HomeController < ApplicationController
	def index
		p params
		
		tuner_params = params[:tuner]
		@tuner = tuner_params.nil? ? Tuner.first : Tuner.find(tuner_params[:id])
		@logs = Log.all(:joins => ', stations', :select => 'logs.*, stations.*, max(logs.created_at) as log_time', :conditions => ['stations.id = logs.station_id and tuner_id = ?', @tuner.id], :group => 'callsign')
# 		@logs = Log.all
# 		if params[:location].nil?
			@map_location = { 'latitude' => CONFIG['latitude'], 'longitude' => CONFIG['longitude'] }
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
