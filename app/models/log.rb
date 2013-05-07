class Log < ActiveRecord::Base
  belongs_to :station
  belongs_to :tuner
  
  after_save :update_recent_logs
  
private
  def update_recent_logs
    recent_log = RecentLog.where(:station_id => self.station_id).where(:tuner_id => self.tuner_id).first
    if recent_log.nil?
      recent_log = RecentLog.new
    end
    
    recent_log.attributes = self.attributes
    recent_log.save!
  end
end
