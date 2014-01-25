class Tuner < ActiveRecord::Base
  has_many :tuner_info, :dependent => :destroy
  has_many :logs
  has_many :stations, :through => :logs

  accepts_nested_attributes_for :tuner_info, :allow_destroy => :true

  acts_as_list
  default_scope :order => "position"
  before_destroy :clear_tuner_infos
  
  def current
    tuner_info[tuner_info.length - 1]
  end

  def full_name
    "#{tuner_id}:#{tuner_number}"
  end
  
  def logs_since(time_interval)    
    query = RecentLog.where(:tuner_id => id)
    
    query = query.where('updated_at > ? ', time_interval.date_range.begin) unless time_interval.all_interval?
    
    return query
  end

protected
  def clear_tuner_infos
    tuner_info.clear
  end
end
