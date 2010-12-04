class Tuner < ActiveRecord::Base
	has_many :tuner_info, :dependent => :destroy
	has_many :logs
	has_many :stations, :through => :logs

	accepts_nested_attributes_for :tuner_info, :allow_destroy => :true

	def current
		return tuner_info[tuner_info.length - 1]
	end

	def name
		return tuner_id + ':' + tuner_number.to_s
	end
end
