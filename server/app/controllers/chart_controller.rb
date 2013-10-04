class ChartController < ApplicationController
  def index
    @station = params[:station_id].nil? ? Station.first : Station.find(params[:station_id])
    @tuner = params[:tuner_id].nil? ? Tuner.first : Tuner.find(params[:tuner_id])
    @logs = Log.all(:conditions => ['station_id = ? and tuner_id = ?', @station.id, @tuner.id], :group => 'date(created_at)')

    @data = []
    i = 0
    empty = {
      :signal_strength => 0,
      :signal_to_noise => 0,
      :signal_quality => 0
    }
    
    (@logs.first.created_at.to_date..@logs.last.created_at.to_date).each do |date|
      log = @logs[i]
      
      if log.created_at.to_date == date
        @data << {
          :signal_strength => log.signal_strength,
          :signal_to_noise => log.signal_to_noise,
          :signal_quality => log.signal_quality
        }
        i += 1
      else
        @data << empty
      end
    end

    respond_to do |format|
      format.html # index.html.erb
    end
  end
end
