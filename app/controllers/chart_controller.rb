class ChartController < ApplicationController
  def index
    @station = params[:station_id].nil? ? Station.first : Station.find(params[:station_id])
    @tuner = params[:tuner_id].nil? ? Tuner.first : Tuner.find(params[:tuner_id])
    @logs = Log.select('date(created_at) as created_at, avg(signal_strength) as signal_strength, avg(signal_to_noise) as signal_to_noise, avg(signal_quality) as signal_quality')
               .where(station_id: @station.id)
               .where(tuner_id: @tuner.id)
               .where('created_at > ?', Time.now-30.days)
               .group(1)
               .order(1)
    
    @data = []
    
    prevlog = @logs.shift
    @data.push prevlog
    @logs.each do |log|
        if (log.created_at - prevlog.created_at) > 86400
            @data.push nil
        end
        
        @data.push log
        
        prevlog = log
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js # index.js.erb
    end
  end
end
