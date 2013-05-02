// Additions to the standard Google Maps APIs

// specifies whether a map marker is open or not
google.maps.Marker.prototype.isOpen = false;

// When a marker is clicked, display its InfoWindow and raise it up
google.maps.Marker.prototype.click = function()
{
  var map = this.getMap();
  if(map.activeMarker != this || !this.isOpen)
  {
    map.setActiveMarker(this);
    this.setZIndex(2);
    this.infoWindow.open(this.getMap(), this);
    this.isOpen = true;
  }
};

// keep track of the markers on the map
google.maps.Map.prototype.markers = Array();

// keep track of which marker is active, so we can close it when another is clicked
google.maps.Map.prototype.activeMarker = false;

// close the active marker's InfoWindow if there is one (reverse of Marker.click())
google.maps.Map.prototype.clearActiveMarker = function()
{
  if(this.activeMarker)
  {
    this.activeMarker.infoWindow.close();
    this.activeMarker.setZIndex(0);
    this.activeMarker.isOpen = false;
  }
}

// set the active marker to marker, clearing the previous
google.maps.Map.prototype.setActiveMarker = function(marker)
{
  this.clearActiveMarker();

  this.activeMarker = marker;
}

// Add a marker to the map. Wraps the marker constructor and adds it to the map's marker list
google.maps.Map.prototype.addMarker = function(object)
{
  object.map = this;

  var marker =  new google.maps.Marker(object);

  this.markers.push(marker);
  
  return marker;
}

// Clear all markers from the map
google.maps.Map.prototype.clearMarkers = function()
{
  this.clearActiveMarker();
  
  for(var i = 0; i < this.markers.length; i++)
  {
    this.markers[i].setMap(null);
  }
}

// Remove references to the markers contained in the map, deleting them
google.maps.Map.prototype.removeMarkers = function()
{
  this.clearMarkers();

  this.markers.length = 0;
}


// function addPoint(marker)
// {
//   var position = marker.getPosition();
//   var lat = position.lat();
//   var long = position.lng();
// 
//   if(!markerpoints[lat])
//   {
//     markerpoints[lat] = new Array();
//   }
//   if(!markerpoints[lat][long])
//   {
//     markerpoints[lat][long] = new Array();
//   }
// 
//   markerpoints[lat][long].push(marker);
// }

// function moveMarker(marker, degree, distance)
// {
//     var R = 6371; // km
//     var dLat = (lat2-lat1).toRad();
//     var dLon = (lon2-lon1).toRad();
//     var a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(lat1.toRad()) * Math.cos(lat2.toRad()) * Math.sin(dLon/2) * Math.sin(dLon/2);
//     var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
//     var d = R * c;
//   var rad = degree * Math.PI/180
//   var x = distance * Math.cos(rad);
//   var y = distance * Math.sin(rad);
// 
//   var pos = marker.getPosition();
//   var newpos = new google.maps.LatLng(pos.lat() + y, pos.lng() + x)
//   marker.setPosition(newpos);
//   marker.setZIndex(1);
//   var line = new google.maps.Polyline({
//     path: [pos, newpos]
//   });
//   lines.push(line);
//   line.setMap(map);
// }

// function clearMoved()
// {
//   for(var i = 0; i < movedmarkers.length; i++)
//   {
//     var oldpos = lines[i].getPath().getAt(0);
//     movedmarkers[i].setPosition(oldpos);
//     movedmarkers[i].setZIndex(0);
//     lines[i].setMap();
//   }
// }
// function checkMove()
// {
//   var actmarker = markers[active];
//   for(var i = 0; i < movedmarkers.length; i++)
//   {
//     if(movedmarkers[i] == actmarker) return;
//   }
// 
//   clearMoved();
// 
//   var lat = actmarker.getPosition().lat();
//   var long = actmarker.getPosition().lng();
//   var zoom = map.getZoom();
//   var factor = 8 / zoom * 8 * 10 / 3600;
// 
//   if(markerpoints[lat][long].length > 1)
//   {
//     var degrees = 360 / markerpoints[lat][long].length;
//     degrees = degrees > 120 ? 120 : degrees;
//     var start = Math.floor(Math.random() * 360)
//     var distance = markerpoints[lat][long].length * factor;
// 
//     movedmarkers = new Array();
//     lines = new Array();
// 
//     for(var i = 0; i < markerpoints[lat][long].length; i++)
//     {
//       var marker = markerpoints[lat][long][i];
//       moveMarker(marker, start + degrees * i, distance);
//       movedmarkers.push(marker);
//     }
//   }
// }
