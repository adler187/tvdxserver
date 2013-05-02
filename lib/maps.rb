
def get_marker_image(ss)
  if ss > 70
    return "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/green-dot.png"
  elsif ss > 50
    return "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/yellow-dot.png"
  else
    return "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/red-dot.png"
  end
end

def info_window(log)
  station = log.station
  
  content = ''
  content += link_to station.callsign, "http://www.rabbitears.info/market.php?request=station_search&callsign=#{station.callsign}#station", { :target => 'station_lookup' }
  content += '<br /><hr>Last received on ' + log.created_at.to_s + '<br />'
  content += 'Channel: ' + station.rf.to_s + '<br />'  
  content += 'Distance: ' + station.distance.round(2).to_s + ' mi<br />'
  content += 'Most recent scan: <br />'
  content += 'Signal Strength: ' + log.signal_strength.to_s + '<br />'
  content += 'Signal to Noise: ' + log.signal_to_noise.to_s + '<br />'
  content += 'Signal Quality: ' + log.signal_quality.to_s + '<br />'
  content += link_to 'Signal Graph', "/chart/#{station.id}/#{log.tuner.id}", { :target => 'signal_graph' }
end
