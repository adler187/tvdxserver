<?php include "config.php"; ?>
<?php
$conn = mysql_connect($cfg['db']['host'], $cfg['db']['username'], $cfg['db']['password']);
if(!$conn) die("Couldn't connect to host");

if(!mysql_select_db($cfg['db']['db'])) die("Couldn't select the database");

function getMarkerImage($ss, $snq, $seq)
{
	if($ss > 70)
		return "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/green-dot.png";
	else if($ss > 50)
		return "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/yellow-dot.png";
	else
		return "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/red-dot.png";
}
?>
<html>
<head>
<title>Stations received by <?php echo $user; ?></title>

<!-- <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;sensor=false&amp;key=<?php echo $key; ?>" type="text/javascript"></script> -->
<meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
<script src="http://maps.google.com/maps/api/js?sensor=false"></script>
<script type="text/javascript">
	active = -1;
	markers = new Array();
	infowindows = new Array();
	markerpoints = new Array();
	movedmarkers = new Array();
	lines = new Array();

	function clearActive()
	{
		if(active == -1)
			myinfowindow.close();
		else
		{
			var actmarker = markers[active];
			for(var i = 0; i < movedmarkers.length; i++)
			{
				if(movedmarkers[i] == actmarker) actmarker.setZIndex(1);
			}
			infowindows[active].close();
		}
	}

	function addPoint(marker)
	{
		var position = marker.getPosition();
		var lat = position.lat();
		var long = position.lng();
		
		if(!markerpoints[lat])
		{
			markerpoints[lat] = new Array();
		}
		if(!markerpoints[lat][long])
		{
			markerpoints[lat][long] = new Array();
		}
		
		markerpoints[lat][long].push(marker);
	}
	
	function moveMarker(marker, degree, distance)
	{
// 		var R = 6371; // km
// 		var dLat = (lat2-lat1).toRad();
// 		var dLon = (lon2-lon1).toRad(); 
// 		var a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(lat1.toRad()) * Math.cos(lat2.toRad()) * Math.sin(dLon/2) * Math.sin(dLon/2); 
// 		var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
// 		var d = R * c;
		var rad = degree * Math.PI/180
		var x = distance * Math.cos(rad);
		var y = distance * Math.sin(rad);
		
		var pos = marker.getPosition();
		var newpos = new google.maps.LatLng(pos.lat() + y, pos.lng() + x)
		marker.setPosition(newpos);
		marker.setZIndex(1);
		var line = new google.maps.Polyline({
			path: [pos, newpos]
		});
		lines.push(line);
		line.setMap(map);
	}
	
	function clearMoved()
	{
		for(var i = 0; i < movedmarkers.length; i++)
		{
			var oldpos = lines[i].getPath().getAt(0);
			movedmarkers[i].setPosition(oldpos);
			movedmarkers[i].setZIndex(0);
			lines[i].setMap();
		}
	}
	function checkMove()
	{
		var actmarker = markers[active];
		for(var i = 0; i < movedmarkers.length; i++)
		{
			if(movedmarkers[i] == actmarker) return;
		}
		
		clearMoved();
		
		var lat = actmarker.getPosition().lat();
		var long = actmarker.getPosition().lng();
		var zoom = map.getZoom();
		var factor = 8 / zoom * 8 * 10 / 3600;
		
		if(markerpoints[lat][long].length > 1)
		{
			var degrees = 360 / markerpoints[lat][long].length;
			degrees = degrees > 120 ? 120 : degrees;
			var start = Math.floor(Math.random() * 360)
			var distance = markerpoints[lat][long].length * factor;
			
			movedmarkers = new Array();
			lines = new Array();
			
			for(var i = 0; i < markerpoints[lat][long].length; i++)
			{
				var marker = markerpoints[lat][long][i];
				moveMarker(marker, start + degrees * i, distance);
				movedmarkers.push(marker);
			}
		}
	}

	function initialize()
	{
		var mylatlng = new google.maps.LatLng(<?php echo $latitude; ?>, <?php echo $longitude; ?>);
		var myOptions =
		{
			zoom: 7,
			center: mylatlng,
			disableDefaultUI: true,
			mapTypeId: google.maps.MapTypeId.ROADMAP
		};
		map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
		
		google.maps.event.addListener(map, 'click', function() {
			clearActive();
			clearMoved();
		});

// 		google.maps.event.addListener(map, 'zoom_changed', function() {
// 			var zoom = map.getZoom();
// 			if(zoom < 8) map.setZoom(8);
// 		});
		
		mymarker = new google.maps.Marker(
		{
			position: mylatlng,
			map: map,
			draggable: false,
			clickable: true,
			title:"<?php echo $user; ?>",
			icon: "http://maps.gstatic.com/intl/en_us/mapfiles/ms/micons/homegardenbusiness.png"
		});

		myinfowindow = new google.maps.InfoWindow({
			content: '<?php echo $user ?>'
		});
		google.maps.event.addListener(mymarker, 'click', function() {
			clearActive();
			myinfowindow.open(map, mymarker);
			active=-1;
		});
<?php
$query = "SELECT
	stations.callsign,
	stations.latitude,
	stations.longitude,
	log.ss,
	log.snq,
	log.seq,
	MAX(log.logtime) as logtime
FROM stations, log
WHERE
	stations.callsign = log.callsign AND
	stations.tsid = stations.tsid AND logtime > CONCAT(DATE_SUB(CURRENT_DATE(), interval 2 day), ' ', CURRENT_TIME()) AND
	stations.callsign in (
		SELECT distinct callsign from stations )
GROUP BY(stations.callsign)";

$stmt = mysql_query($query);

$i = 0;
while($row = mysql_fetch_assoc($stmt))
{
	$callsign = $row['callsign'];
	$latitude = $row['latitude'];
	$longitude = $row['longitude'];
	$ss = $row['ss'];
	$snq = $row['snq'];
	$seq = $row['seq'];
	$time = $row['logtime'];

	echo "markers[$i] = new google.maps.Marker(
{
	position: new google.maps.LatLng($latitude, $longitude),
	map: map,
	draggable: false,
	clickable: true,
	title:'$callsign',
	zIndex: 0,
	icon: '".getMarkerImage($ss, $snq, $seq)."'
});\n";

	echo "infowindows[$i] = new google.maps.InfoWindow({
	content:	'$callsign<br />' +
				'<hr>' +
				'Last received on $time<br />' +
				'Most recent scan:<br />' +
				'Signal Strength: $ss<br />' +
				'Signal Quality: $snq<br />' +
				'Symbol Quality: $seq<br />' +
				'<br />' +
				'<a href=\"http://rabbitears.info/market.php?request=station_search&callsign=$callsign#station\" target=\"_blank\">RabbitEars lookup</a>'
});\n";

	echo "google.maps.event.addListener(markers[$i], 'click', function() {
	clearActive();
	active=$i;
	checkMove();
	markers[$i].setZIndex(2);
	infowindows[$i].open(map, markers[$i]);
});\n";

	echo "addPoint(markers[$i]);\n";

	echo "\n";
	$i++;
}
?>
	}
</script>
<!--<script src="map_data.js" type="text/javascript"></script>
<script src="labeled_marker.js" type="text/javascript"></script>
<script src="map_functions.js" type="text/javascript"></script>
<script src="time.js" type="text/javascript"></script>-->
<!-- <link href="style.css" rel="stylesheet" type="text/css" /> -->
</head>

<body onload='initialize()'>
<!--<div id="toolbar">
	<h1> TV stations received by <?php echo "$user in $city, $state"; ?></h1>
	<img src="green_dot.png" width='15' height='15' /> Strong signal
	<img src="yellow_dot.png" width='15' height='15' /> Medium signal
	<img src="red_dot.png" width='15' height='15' /> Weak signal
	<img src="black_dot.png" width='15' height='15' /> Detected in last 48 hours, but not currently<br />
	Zoom in for more stations.  Click a call sign for more details.<br />
	This page updates every five minutes.<br /><br />
	<a href="/cricket/grapher.cgi?target=%2FTV">Click here for graphs of signal strength for all stations ever received</a>
</div>-->
<div id="content">
<!-- <div id="map-wrapper"> -->
	<div id="map_canvas" style="width:100%; height:100%"></div>
<!-- </div> -->
<!--<div id="sidebar">
Click text to locate station on map
<ul id="sidebar-list">
</ul>
</div>-->
</div>
</body>
</html>
