class TunersController < ApplicationController
	
  before_filter :authenticate
	
	# GET /tuners
	# GET /tuners.xml
	def index
		@tuners = Tuner.all

		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => @tuners }
		end
	end

	# GET /tuners/1
	# GET /tuners/1.xml
	def show
		@tuner = Tuner.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.xml  { render :xml => @tuner }
		end
	end

	# GET /tuners/new
	# GET /tuners/new.xml
	def new
		@tuner = Tuner.new
		@tuner_info = @tuner.tuner_info.build

		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @tuner }
		end
	end

	# GET /tuners/1/edit
	def edit
		@tuner = Tuner.find(params[:id])
	end

	# POST /tuners
	# POST /tuners.xml
	def create
		tuner_params = params[:tuner]
		info_params = tuner_params[:tuner_info]
		tuner_params.delete(:tuner_info)
		
		@tuner = Tuner.new(tuner_params)
		@tuner_info = @tuner.tuner_info.build(info_params)

		respond_to do |format|
			if @tuner.save
				format.html { redirect_to(@tuner, :notice => 'Tuner was successfully created.') }
				format.xml  { render :xml => @tuner, :status => :created, :location => @tuner }
			else
				format.html { render :action => "new" }
				format.xml  { render :xml => @tuner.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /tuners/1
	# PUT /tuners/1.xml
	def update
		@tuner = Tuner.find(params[:id])
		info_params = params[:tuner][:tuner_info]
		
		@tuner_info = @tuner.tuner_info.build(info_params)

		respond_to do |format|
			if @tuner_info.save
				format.html { redirect_to(@tuner, :notice => 'Tuner was successfully updated.') }
				format.xml  { head :ok }
			else
				format.html { render :action => "edit" }
				format.xml  { render :xml => @tuner_info.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /tuners/1
	# DELETE /tuners/1.xml
	def destroy
		@tuner = Tuner.find(params[:id])
		@tuner.destroy

		respond_to do |format|
			format.html { redirect_to(tuners_url) }
			format.xml  { head :ok }
		end
	end
end
