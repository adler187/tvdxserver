class TimeIntervalsController < ApplicationController
	
  before_filter :authenticate

	def help
		Helper.instance
	end

	class Helper
		include Singleton
		include ActionView::Helpers::TextHelper
	end
	
	def index
    @time_intervals = TimeInterval.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @time_intervals }
    end
  end

  # GET /time_intervals/1
  # GET /time_intervals/1.xml
  def show
    @time_interval = TimeInterval.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @time_interval }
    end
  end

  # GET /time_intervals/new
  # GET /time_intervals/new.xml
  def new
    @time_interval = TimeInterval.new
	@options = Array.new
	TimeInterval.valid_units.each do |unit|
		@options.push [unit.capitalize, unit]
	end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @time_interval }
    end
  end

  # GET /time_intervals/1/edit
  def edit
    @time_interval = TimeInterval.find(params[:id])
  end

  # POST /time_intervals
  # POST /time_intervals.xml
  def create
	  parms = params[:time_interval]
	parms[:description] = help.pluralize(parms[:interval], parms[:unit]) + ' ago'
    @time_interval = TimeInterval.new(parms)

    respond_to do |format|
      if @time_interval.save
        format.html { redirect_to(@time_interval, :notice => 'TimeInterval was successfully created.') }
        format.xml  { render :xml => @time_interval, :status => :created, :location => @time_interval }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @time_interval.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /time_intervals/1
  # PUT /time_intervals/1.xml
  def update
    @time_interval = TimeInterval.find(params[:id])

    respond_to do |format|
      if @time_interval.update_attributes(params[:time_interval])
        format.html { redirect_to(@time_interval, :notice => 'TimeInterval was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @time_interval.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /time_intervals/1
  # DELETE /time_intervals/1.xml
  def destroy
    @time_interval = TimeInterval.find(params[:id])
    @time_interval.destroy

    respond_to do |format|
      format.html { redirect_to(time_intervals_url) }
      format.xml  { head :ok }
    end
  end
end
