class HomeController < ApplicationController
	def index
		time_params = params[:time_interval]
		time_range = (time_params.nil? ? TimeInterval.first : TimeInterval.find(time_params[:id])).date_range

		tuner_params = params[:tuner]
		@tuner = tuner_params.nil? ? Tuner.first : Tuner.find(tuner_params[:id])
		@logs = Log.all(:joins => ', stations', :select => 'logs.*, stations.*, max(logs.created_at) as log_time', :conditions => ['stations.id = logs.station_id and tuner_id = ? and logs.created_at between ? and ?', @tuner.id, time_range.begin.utc, time_range.end.utc], :group => 'callsign')

		@map_location = { :latitude => CONFIG['latitude'], :longitude => CONFIG['longitude'] }

		@zoom = 8
		
		respond_to do |format|
			format.html # index.html.erb
			format.json  { render :json => @logs }
			format.js
		end
	end
end
