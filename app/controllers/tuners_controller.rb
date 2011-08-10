class TunersController < ApplicationController
  
  before_filter :authenticate
  
  make_resourceful do
    actions :all
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
  
  def sort
    params[:tuners].each_with_index do |id, index|
      Tuner.update_all(['position=?', index+1], ['id=?', id])
    end
    
    render :nothing => true
  end
end
