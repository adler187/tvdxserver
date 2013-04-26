class StationsController < ApplicationController
	
  before_filter :authenticate

  def index
    @stations = Station.all
    
    respond_to do |format|
      format.html
      format.json { render :json => @stations }
    end
  end

  def show
    @station = Station.find(params[:id])
  end

  def new
    @station = Station.new
  end

  def edit
    @station = Station.find(params[:id])
  end
  
  def create
    @station = Station.new(params[:station])

    if @station.save
      flash[:notice] = 'Station created'
      redirect_to stations_path
    else
      flash[:error] = 'Error creating Station'
      render :action => 'new'
    end
  end

  def update
    @station = Station.find(params[:id])

    if @station.update_attributes(params[:station])
      flash[:notice] = 'Station was successfully updated'
      redirect_to @station
    else
      flash[:error] = 'Error updating Station'
      render :action => :edit
    end
  end

  def destroy
    begin
      Station.destroy(params[:id])
      flash[:notice] = 'Station removed'
    rescue
      flash[:error] = $!.message
    end
    
    redirect_to stations_path
  end
  
  def destroy_all
    Station.destroy_all
	  
    redirect_to(stations_url)
  end
end
