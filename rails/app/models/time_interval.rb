class TimeInterval < ActiveRecord::Base
	@@valid_units = %w( month day year hour minute second )
	
	def self.valid_units
		@@valid_units
	end

	def date_range
		if self.unit.nil?
			return Time.at(0)..Time.now
		else
			return self.interval.method(self.unit).call.ago..Time.now
		end
	end
	
	validates_inclusion_of :unit, :in => @@valid_units, :message => "%s is not a valid unit", :allow_nil => true
	validates_uniqueness_of :interval, :scope => :unit
	validates_presence_of :interval, :unless => Proc.new { |time_interval| time_interval.unit.nil? }
	validates_presence_of :unit, :unless => Proc.new { |time_interval| time_interval.interval.nil? }
	validates_presence_of :description
end
