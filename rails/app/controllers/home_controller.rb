class HomeController < ApplicationController
	def index		
		tuner_params = params[:tuner]
		@tuner = tuner_params.nil? ? Tuner.first : Tuner.find(tuner_params[:id])
		@logs = Log.all(:joins => ', stations', :select => 'logs.*, stations.*, max(logs.created_at) as log_time', :conditions => ['stations.id = logs.station_id and tuner_id = ?', @tuner.id], :group => 'callsign')

		if params[:location].nil?
			@map_location = { :latitude => CONFIG['latitude'], :longitude => CONFIG['longitude'] }
		else
			@map_location = params[:location]
		end
		

		if params[:zoom].nil?
			@zoom = params[:zoom]
		else
			@zoom = 8
		end
	end
end
