class Mailer < ActionMailer::Base
  default from: CONFIG['fromemail']

  def new_station_mail(station)
    if !CONFIG['email'].nil?
      @station = station
      mail(to: CONFIG['email'], subject: "New station received: #{station.callsign}")
    end
  end
end
