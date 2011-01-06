
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
	
	content = station.callsign + '<br /><hr>Last received on ' + log.created_at.to_s + '<br />'
	content += 'Channel: ' + station.rf.to_s + '<br />'	
	content += 'Distance: ' + station.distance.round(2).to_s + ' mi<br />'
	content += 'Most recent scan: <br />'
	content += 'Signal Strength: ' + log.signal_strength.to_s + '<br />'
	content += 'Signal to Noize: ' + log.signal_to_noise.to_s + '<br />'
	content += 'Signal Quality: ' + log.signal_quality.to_s + '<br />'
end
