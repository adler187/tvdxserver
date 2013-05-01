class LogsController < ApplicationController
  
  before_filter :authenticate
  
  def index
    @logs = Log.all
  end

  def show
    @log = Log.find(params[:id])
  end

  def new
    @log = Log.new
  end
  
  def edit
    @log = Log.find(params[:id])
  end
  
  def create
    @log = Log.new(params[:log])
    
    respond_to do |format|
      if @log.save
        flash[:notice] = 'Log created'
        
        format.html { redirect_to logs_path }
        format.json { render :json => { :success => true, :request => logs_path, :log => @log.attributes } }
      else
        flash[:error] = 'Error creating Log'
        
        format.html { render :action => 'new' }
        format.json { render :json => { :success => false, :request => logs_path } }
      end
    end
	end

  def update
    @log = Log.find(params[:id])

    if @log.update_attributes(params[:log])
      flash[:notice] = 'Log was successfully updated'
      redirect_to(@log)
    else
      flash[:error] = 'Log was not updated'
      render :action => "edit" 
    end
  end
  
  def destroy
    @log = Log.find(params[:id])
    @log.destroy
    
    respond_to do |format|
      format.html { redirect_to logs_url }
    end
  end
  
  def sort
    params[:logs].each_with_index do |id, index|
      Log.update_all(['position=?', index+1], ['id=?', id])
    end
    
    render :nothing => true
  end
end
