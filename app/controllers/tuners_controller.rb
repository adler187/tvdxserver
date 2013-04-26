class TunersController < ApplicationController
  
  before_filter :authenticate

  def index
    tuner_number = params[:tuner_number]
    tuner_id = params[:tuner_id]
    
    if tuner_number && tuner_id
      @tuners = Tuner.where(:tuner_number => tuner_number).where(:tuner_id => tuner_id)
    else
      @tuners = Tuner.all
    end
    
    respond_to do |format|
      format.html
      format.json { render :json => @tuners }
    end
  end

  def show
    @tuner = Tuner.find(params[:id])
  end

  def new
    @tuner = Tuner.new
  end
  
  def edit
    @tuner = Tuner.find(params[:id])
  end
  
  def create
		tuner_params = params[:tuner]
		info_params = tuner_params[:tuner_info]
		tuner_params.delete(:tuner_info)
		
		@tuner = Tuner.new(tuner_params)
		@tuner_info = @tuner.tuner_info.build(info_params)

    if @tuner.save
      flash[:notice] = 'Tuner was successfully created'
      redirect_to tuners_path
    else
      flash[:notice] = 'Tuner was successfully created'
      render :action => "new"
    end
	end

  def update
    @tuner = Tuner.find(params[:id])
    info_params = params[:tuner][:tuner_info]
    
    @tuner_info = @tuner.tuner_info.build(info_params)

    if @tuner_info.save
      flash[:notice] = 'Tuner was successfully updated'
      redirect_to(@tuner)
    else
      flash[:error] = 'Tuner was not updated'
      render :action => "edit" 
    end
  end
  
  def destroy
    begin
      Tuner.destroy(params[:id])
      flash[:notice] = 'Tuner removed'
    rescue
      flash[:error] = $!.message
    end
    
    redirect_to tuners_path
  end
  
  def sort
    params[:tuners].each_with_index do |id, index|
      Tuner.update_all(['position=?', index+1], ['id=?', id])
    end
    
    render :nothing => true
  end
end
