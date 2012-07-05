class TimeInterval < ActiveRecord::Base
	@@VALID_UNITS = %w( month day year hour minute second )
	
  validates_inclusion_of :unit, :in => @@VALID_UNITS, :message => "%s is not a valid unit", :allow_nil => true
  
  validates_uniqueness_of :interval, :scope => :unit
  validates_uniqueness_of :position
  
  validates_presence_of :interval, :unless => Proc.new { |time_interval| time_interval.unit.nil? }
  validates_presence_of :unit, :unless => Proc.new { |time_interval| time_interval.interval.nil? }
  
  before_destroy :prevent_delete_all_interval
  
  acts_as_list
  default_scope :order => "position"
  
  def helpers
    ActionController::Base.helpers
  end
  
	def self.valid_units
		@@VALID_UNITS
	end

	def date_range
		if self.unit.nil?
			return Time.at(0)..Time.now
		else
			return self.interval.method(self.unit).call.ago..Time.now
		end
	end
  
  def description
    if(all_interval?)
      'All'
    else
      "#{helpers.pluralize(interval, unit)} ago"
    end
  end
  
  def all_interval?
    unit.nil? && interval.nil?
  end
  
  def self.all_interval
    @all_interval ||= TimeInterval.where(:unit => nil, :interval => nil).first
  end
  
  private
  
  def prevent_delete_all_interval
    if all_interval?
      raise "Cannot delete time interval 'All'"
    end
  end
  
end
