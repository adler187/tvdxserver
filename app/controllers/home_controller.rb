class HomeController < ApplicationController
  def index
    time_params = params[:time_interval] || HashWithIndifferentAccess.new(TimeInterval.first.attributes)

    tuner_params = params[:tuner]
    @tuner = tuner_params.nil? ? Tuner.first : Tuner.find(tuner_params[:id])
    if @tuner.nil?
      @logs = Array.new
    else
      @logs = @tuner.logs_since(TimeInterval.find(time_params[:id]))
    end

    @map_location = { :latitude => CONFIG['latitude'], :longitude => CONFIG['longitude'] }

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @logs }
      format.js
    end
  end
end
