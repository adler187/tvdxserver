class TimeIntervalsController < ApplicationController
	
  before_filter :authenticate
	
	def index
    @time_intervals = TimeInterval.all
  end

  def show
    @time_interval = TimeInterval.find(params[:id])
  end

  def new
    @time_interval = TimeInterval.new
    @options = TimeInterval.valid_units.collect { |unit| [unit.capitalize, unit] };
  end

  def create
    @time_interval = TimeInterval.new(params[:time_interval])

    if @time_interval.save
      flash[:notice] = 'Time Interval created'
      redirect_to time_intervals_path
    else
      flash[:error] = 'Error creating Time Interval'
      render :action => 'new'
    end
  end

  def update
    @time_interval = TimeInterval.find(params[:id])

    if @time_interval.update_attributes(params[:time_interval])
      flash[:notice] = 'TimeInterval was successfully updated'
      redirect_to @time_interval
    else
      flash[:error] = 'Error updating TimeInterval'
      render :action => :edit
    end
  end

  def destroy
    begin
      TimeInterval.destroy(params[:id])
      flash[:notice] = 'Time Interval removed'
    rescue
      flash[:error] = $!.message
    end
    
    redirect_to time_intervals_path
  end
  
  def sort
    params[:time_intervals].each_with_index do |id, index|
      TimeInterval.update_all(['position=?', index+1], ['id=?', id])
    end
    
    render :nothing => true
  end
end
