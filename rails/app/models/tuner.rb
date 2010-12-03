class Tuner < ActiveRecord::Base
	has_many :tuner_info, :dependent => :destroy

	accepts_nested_attributes_for :tuner_info, :allow_destroy => :true

	def current
		return tuner_info[tuner_info.length - 1]
	end
end
