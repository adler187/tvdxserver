active = undefined;
markers = new Hash();
// infowindows = new Hash();
// markerpoints = new Array();
// movedmarkers = new Array();
// lines = new Array();
// maxZindex = 0;
// oldZindex = 0;

function markerClick(m)
{
	return (function()
	{
		clearActive();
		active = m;

		m.setZIndex(2);
		m.infoWindow.open(m.getMap(), m);
	});
}

function clearActive()
{
	if(typeof active !== 'undefined')
	{
		active.infoWindow.close();
	}
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