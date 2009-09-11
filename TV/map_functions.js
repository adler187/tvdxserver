// based on example from http://uwmike.com/maps/manhattan2/map_functions.js
var map, manager;


function createMarkerClickHandler(marker, text, link) {
  return function() {
  marker.openInfoWindowHtml(
    '<h3>' + text + '</h3>' +
    '<p><a href="' + link + '">Signal strength graphs</a></p>'
  );
  return false;
  };
}


function createMarker(pointData, color) {
	var latlng = new GLatLng(pointData.latitude, pointData.longitude);
	var icon = new GIcon();
	icon.image = 'http://kb8u.ham-radio-op.net/TV/' + color + '_dot.png';
	icon.iconSize = new GSize(32, 32);
	icon.iconAnchor = new GPoint(16, 16);
	icon.infoWindowAnchor = new GPoint(25, 7);
	opts = {
		"icon": icon,
		"clickable": true,
		"labelText": pointData.call,
		"labelOffset": new GSize(-16, -16)
	};
	var marker = new LabeledMarker(latlng, opts);
	var handler = createMarkerClickHandler(marker, pointData.call + " " + pointData.info, pointData.graph);
	
	GEvent.addListener(marker, "click", handler);

	// zoomed-out points are redundant so they don't get added again
	if (pointData.strongest != 1) {
	  var listItem = document.createElement('li');
	  listItem.innerHTML = '<div class="label">'+pointData.call+'</div><a href="' + pointData.graph + '">' + pointData.info + '</a>';
	  listItem.getElementsByTagName('a')[0].onclick = handler;

	  document.getElementById('sidebar-list').appendChild(listItem);
	}

	return marker;
}


function windowHeight() {
	// Standard browsers (Mozilla, Safari, etc.)
	if (self.innerHeight)
		return self.innerHeight;
	// IE 6
	if (document.documentElement && document.documentElement.clientHeight)
		return document.documentElement.clientHeight;
	// IE 5
	if (document.body)
		return document.body.clientHeight;
	// Just in case. 
	return 0;
}

function handleResize() {
	var height = windowHeight() - document.getElementById('toolbar').offsetHeight - 30;
	document.getElementById('map').style.height = height + 'px';
	document.getElementById('sidebar').style.height = height + 'px';
}

function init() {
  handleResize();
  
  map = new GMap(document.getElementById("map"));
  map.addControl(new GSmallMapControl());
  map.addControl(new GMapTypeControl());
  map.setCenter(new GLatLng(0,0),0);

  var bounds = new GLatLngBounds();

  manager = new GMarkerManager(map);
  green_markers.sort(function(a, b) { return (a.info > b.info) ? +1 : -1; }); 
  yellow_markers.sort(function(a, b) { return (a.info > b.info) ? +1 : -1; }); 
  red_markers.sort(function(a, b) { return (a.info > b.info) ? +1 : -1; }); 
  
  // add all markers for zoom levels 8 and greater
  black_batch = [];
  for(id in black_markers) {
    black_batch.push(createMarker(black_markers[id],'black'));
    var lat = parseFloat(black_markers[id].latitude);
    var lng = parseFloat(black_markers[id].longitude);
    var point = new GLatLng(lat,lng);
    bounds.extend(point);
  }
  manager.addMarkers(black_batch, 8);

  black_strongest_batch = [];
  for(id in black_strongest_markers) {
    black_strongest_batch.push(createMarker(black_strongest_markers[id],'black'));
    var lat = parseFloat(black_strongest_markers[id].latitude);
    var lng = parseFloat(black_strongest_markers[id].longitude);
    var point = new GLatLng(lat,lng);
    bounds.extend(point);
  }
  manager.addMarkers(black_strongest_batch, 0, 7);

  red_batch = [];
  for(id in red_markers) {
    red_batch.push(createMarker(red_markers[id],'red'));
    var lat = parseFloat(red_markers[id].latitude);
    var lng = parseFloat(red_markers[id].longitude);
    var point = new GLatLng(lat,lng);
    bounds.extend(point);
  }
  manager.addMarkers(red_batch, 8);

  red_strongest_batch = [];
  for(id in red_strongest_markers) {
    red_strongest_batch.push(createMarker(red_strongest_markers[id],'red'));
    var lat = parseFloat(red_strongest_markers[id].latitude);
    var lng = parseFloat(red_strongest_markers[id].longitude);
    var point = new GLatLng(lat,lng);
    bounds.extend(point);
  }
  manager.addMarkers(red_strongest_batch, 0, 7);

  yellow_batch = [];
  for(id in yellow_markers) {
    yellow_batch.push(createMarker(yellow_markers[id],'yellow'));
    var lat = parseFloat(yellow_markers[id].latitude);
    var lng = parseFloat(yellow_markers[id].longitude);
    var point = new GLatLng(lat,lng);
    bounds.extend(point);
  }
  manager.addMarkers(yellow_batch, 8);

  yellow_strongest_batch = [];
  for(id in yellow_strongest_markers) {
    yellow_strongest_batch.push(createMarker(yellow_strongest_markers[id],'yellow'));
    var lat = parseFloat(yellow_strongest_markers[id].latitude);
    var lng = parseFloat(yellow_strongest_markers[id].longitude);
    var point = new GLatLng(lat,lng);
    bounds.extend(point);
  }
  manager.addMarkers(yellow_strongest_batch, 0, 7);

  green_batch = [];
  for(id in green_markers) {
    green_batch.push(createMarker(green_markers[id],'green'));
    var lat = parseFloat(green_markers[id].latitude);
    var lng = parseFloat(green_markers[id].longitude);
    var point = new GLatLng(lat,lng);
    bounds.extend(point);
  }
  manager.addMarkers(green_batch, 8);

  green_strongest_batch = [];
  for(id in green_strongest_markers) {
    green_strongest_batch.push(createMarker(green_strongest_markers[id],'green'));
    var lat = parseFloat(green_strongest_markers[id].latitude);
    var lng = parseFloat(green_strongest_markers[id].longitude);
    var point = new GLatLng(lat,lng);
    bounds.extend(point);
  }
  manager.addMarkers(green_strongest_batch, 0, 7);

  // ===== determine the zoom level from the bounds =====
  map.setZoom(map.getBoundsZoomLevel(bounds));

  // ===== determine the centre from the bounds ======
  map.setCenter(bounds.getCenter());

  // markers are rendered here
  manager.refresh();

  // reload every 5 minutes
  setTimeout("window.location.reload(true)",300000);
}

window.onresize = handleResize;
window.onload = init;
window.onunload = GUnload;
