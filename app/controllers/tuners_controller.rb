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
    id = params[:id]
    unless id.nil?
      @tuner = Tuner.find(id)
      flash[:error] = "Tuner id #{id}" if @tuner.nil?
    else
      @tuner = Tuner.where(:tuner_id => params[:tuner_id], :tuner_number => params[:tuner_number]).first
      flash[:error] = "Tuner #{params[:tuner_id]}:#{params[:tuner_number]}" if @tuner.nil?
    end
        
    redirect_to tuners_path if @tuner.nil?
    
    respond_to do |format|
      format.html
      format.json { render :json => @tuner.attributes }
    end
  end

  def new
    @tuner = Tuner.new
  end
  
  def edit
    @tuner = Tuner.find(params[:id])
  end
  
  def create
    tuner_params = params[:tuner]
    @tuner = Tuner.new(tuner_params)

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

    respond_to do |format|
      if @tuner.update_attributes(params[:tuner])
        format.html { redirect_to @tuner, notice: 'Tuner was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tuner.errors, status: :unprocessable_entity }
      end
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
