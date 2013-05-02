class Log < ActiveRecord::Base
  belongs_to :station
  belongs_to :tuner
end
