class StationsController < ApplicationController
  
  before_filter :authenticate

  def index
    query = {}
    if params[:tsid]
      query[:tsid] = params[:tsid]
    end
    
    if params[:callsign]
      query[:callsign] = params[:callsign]
    end
    
    if params[:display]
      query[:display] = params[:display]
    end
    
    if params[:rf]
      query[:rf] = params[:rf]
    end
    
    if query.size == 0
      @stations = Station.all
    else
      @stations = Station.where(query)
    end
    
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

    respond_to do |format|
      if @station.save
        flash[:notice] = 'Station created'
        format.html { redirect_to stations_path }
        format.json { render :json => { :success => true, :request => stations_path, :station => @station.attributes } }
      else
        flash[:error] = 'Error creating Station'
        
        format.html { render :action => 'new' }
        format.json { render :json => { :success => false, :request => stations_path } }
      end
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
