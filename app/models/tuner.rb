class Tuner < ActiveRecord::Base
  has_many :tuner_info, :dependent => :destroy
  has_many :logs
  has_many :stations, :through => :logs

  accepts_nested_attributes_for :tuner_info, :allow_destroy => :true

  acts_as_list
  default_scope :order => "position"
  
  def current
    tuner_info[tuner_info.length - 1]
  end

  def full_name
    "#{tuner_id}:#{tuner_number}"
  end
  
  def logs_since(time_interval)
    logs.all(
      :select => 'logs.*, max(logs.created_at) as log_time, stations.callsign',
      :group => 'stations.callsign',
      :include => [ :station ],
      :conditions => time_interval.all_interval? ? nil : ['logs.created_at > ?', time_interval.date_range.begin.utc]
    )
  end
end
