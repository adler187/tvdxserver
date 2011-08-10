class Station < ActiveRecord::Base
	has_many :logs
	has_many :tuners, :through => :logs
end
