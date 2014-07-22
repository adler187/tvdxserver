class Tuner < ActiveRecord::Base
  has_many :logs
  has_many :stations, :through => :logs

  versioned :if => :version?
  
  acts_as_list
  default_scope :order => "position"
  
  def full_name
    "#{tuner_id}:#{tuner_number}"
  end
  
  def logs_since(time_interval)    
    query = RecentLog.where(:tuner_id => id)
    
    query = query.where('updated_at > ? ', time_interval.date_range.begin) unless time_interval.all_interval?
    
    return query
  end
  
  def version?
    @version ||= ActiveRecord::Base.connection.table_exists? 'versions'
  end
end
