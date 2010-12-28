markers = new Hash();
// infowindows = new Hash();
// markerpoints = new Array();
// movedmarkers = new Array();
// lines = new Array();
// maxZindex = 0;
// oldZindex = 0;

google.maps.Marker.prototype.click = function()
{
	var map = this.getMap();
	if(map.activeMarker != this)
	{
		map.setActiveMarker(this);
		this.setZIndex(2);
		this.infoWindow.open(this.getMap(), this);
	}
};

google.maps.Map.prototype.clearActiveMarker = function()
{
	if(typeof this.activeMarker !== 'undefined')
	{
		this.activeMarker.infoWindow.close();
		this.activeMarker.setZIndex(0);
	}
}

google.maps.Map.prototype.setActiveMarker = function(marker)
{
	this.clearActiveMarker();

	this.activeMarker = marker;
}

google.maps.Map.prototype.addMarker = function(object)
{
	object.map = this;

	var marker =  new google.maps.Marker(object);
	
	if(typeof this.markers === 'undefined')
	{
		this.markers = Array();
	}

	this.markers.push(marker);
	
	return marker;
}

google.maps.Map.prototype.clearMarkers = function()
{
	if(typeof this.markers === 'undefined')
	{
		this.markers = [];
	}

	this.clearActiveMarker();
	
	for(var i = 0; i < this.markers.length; i++)
	{
		this.markers[i].setMap(null);
	}
}

google.maps.Map.prototype.removeMarkers = function()
{
	this.clearMarkers();

	markers.length = 0;
}

function get_marker_image(ss)
{
	if (ss > 70)
		return "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/green-dot.png";
	else if (ss > 50)
		return "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/yellow-dot.png";
	else
		return "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/red-dot.png";
}

function info_window(station)
{
	content = station.callsign + "<br /><hr>\nLast received on " + station.created_at + '<br />';
	content += 'Channel: ' + station.rf + '<br />';
	content += 'Distance: ' + Math.round(station.distance * 100) / 100 + ' mi<br />';
	content += 'Most recent scan: <br />';
	content += 'Signal Strength: ' + station.signal_strength + '<br />';
	content += 'Signal to Noize: ' + station.signal_to_noise + '<br />';
	content += 'Signal Quality: ' + station.signal_quality + '<br />';
	
	return { content: content };
}

function initialize(latitude, longitude, zoom)
{
	handleResize();

	var centerlatlng = new google.maps.LatLng(latitude, longitude);
	var myOptions =
	{
		zoom: zoom,
		center: centerlatlng,
		disableDefaultUI: true,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	
	map = new google.maps.Map(document.getElementById("map"), myOptions);

	google.maps.event.addListener(map, 'click', function()
	{
		map.clearActive();
	});

	addMarkers();
}

function removeMarkers()
{
	document.getElementById('logs-list').innerHTML = '';
	map.removeMarkers();
}

function addMarkers(tuner)
{
	var tuner_select = document.getElementById('tuner_id');
	new Ajax.Request
	(
		'/home.json',
		{
			method:'get',
			parameters: { 'tuner[id]' : tuner_select.options[tuner_select.selectedIndex].value },
			onSuccess: function(transport)
			{
				var list = document.getElementById('logs-list');
				
				var json = transport.responseText.evalJSON();
				for(var i = 0; i < json.length; i++)
				{
					var station = json[i].log;
					
					var marker = map.addMarker
					(
						{
							position: new google.maps.LatLng(station.latitude, station.longitude),
							draggable: false,
							clickable: true,
							title: station.callsign,
							zIndex: 0,
							icon: get_marker_image(station.signal_strength),
							infoWindow: new google.maps.InfoWindow(info_window(station))
						}
					);
					
					google.maps.event.addListener(marker, 'click', marker.click);
					
					var item = document.createElement('span');
					item.innerHTML = station.callsign;
					
					item.marker = marker;
					item.className = 'clickable';
					
					item.onclick = function()
					{
						this.marker.click();
					};
					
					var list_item = document.createElement('li');
					list_item.appendChild(item);
					
					list.appendChild(list_item);
				}
				
			},
			onFailure: function(){ alert('Something went wrong...') }
		}
	);
}

function addPoint(marker)
{
// 	var position = marker.getPosition();
// 	var lat = position.lat();
// 	var long = position.lng();
// 
// 	if(!markerpoints[lat])
// 	{
// 		markerpoints[lat] = new Array();
// 	}
// 	if(!markerpoints[lat][long])
// 	{
// 		markerpoints[lat][long] = new Array();
// 	}
// 
// 	markerpoints[lat][long].push(marker);
}

function moveMarker(marker, degree, distance)
{
// 		var R = 6371; // km
// 		var dLat = (lat2-lat1).toRad();
// 		var dLon = (lon2-lon1).toRad();
// 		var a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(lat1.toRad()) * Math.cos(lat2.toRad()) * Math.sin(dLon/2) * Math.sin(dLon/2);
// 		var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
// 		var d = R * c;
// 	var rad = degree * Math.PI/180
// 	var x = distance * Math.cos(rad);
// 	var y = distance * Math.sin(rad);
// 
// 	var pos = marker.getPosition();
// 	var newpos = new google.maps.LatLng(pos.lat() + y, pos.lng() + x)
// 	marker.setPosition(newpos);
// 	marker.setZIndex(1);
// 	var line = new google.maps.Polyline({
// 		path: [pos, newpos]
// 	});
// 	lines.push(line);
// 	line.setMap(map);
}

function clearMoved()
{
// 	for(var i = 0; i < movedmarkers.length; i++)
// 	{
// 		var oldpos = lines[i].getPath().getAt(0);
// 		movedmarkers[i].setPosition(oldpos);
// 		movedmarkers[i].setZIndex(0);
// 		lines[i].setMap();
// 	}
}
function checkMove()
{
// 	var actmarker = markers[active];
// 	for(var i = 0; i < movedmarkers.length; i++)
// 	{
// 		if(movedmarkers[i] == actmarker) return;
// 	}
// 
// 	clearMoved();
// 
// 	var lat = actmarker.getPosition().lat();
// 	var long = actmarker.getPosition().lng();
// 	var zoom = map.getZoom();
// 	var factor = 8 / zoom * 8 * 10 / 3600;
// 
// 	if(markerpoints[lat][long].length > 1)
// 	{
// 		var degrees = 360 / markerpoints[lat][long].length;
// 		degrees = degrees > 120 ? 120 : degrees;
// 		var start = Math.floor(Math.random() * 360)
// 		var distance = markerpoints[lat][long].length * factor;
// 
// 		movedmarkers = new Array();
// 		lines = new Array();
// 
// 		for(var i = 0; i < markerpoints[lat][long].length; i++)
// 		{
// 			var marker = markerpoints[lat][long][i];
// 			moveMarker(marker, start + degrees * i, distance);
// 			movedmarkers.push(marker);
// 		}
// 	}
}

function handleResize()
{
	var height = self.innerHeight - document.getElementById('top').offsetHeight - 30;
	document.getElementById('map').style.height = height + 'px';
	document.getElementById('logs').style.height = height + 'px';
}

window.onresize = handleResize;