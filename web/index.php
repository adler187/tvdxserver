<?php include "include/config.php"; ?>
<?php include "include/db.php"; ?>
<?php include "include/functions.php"; ?>

<?php
$options = array('48' => 'Last 48 hours', '24' => 'Last 24 Hours', '12' => 'Last 12 Hours', '6' => 'Last 6 Hours', '1' => 'Last hour', 'ALL' => 'All results');

$tuners = array();

$rs = mysql_query("select id, tunerid from tuners");

$tuner = '';

while($row = mysql_fetch_array($rs))
{
	$id = $row[0];
	$tunerid = $row[1];

	$tuners[$id] = $tunerid;
	
	
	if(!$tuner)
	{
		$tuner = $id;
	}
}

if(isset($_POST['tuner']))
{
	$tuner = $_POST['tuner'];
}

$zoom = 6;

if(isset($_POST['zoom']))
{
	$zoom = $_POST['zoom'];
}

$lat = $latitude;
if(isset($_POST['lat']))
{
	$lat = $_POST['lat'];
}

$long = $longitude;
if(isset($_POST['long']))
{
	$long = $_POST['long'];
}

$mobile = checkmobile();

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

<?php
if(!$mobile)
{
?>
<meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
<script src="http://ajax.googleapis.com/ajax/libs/dojo/1.5/dojo/dojo.xd.js" type="text/javascript"></script>
<script src="http://maps.google.com/maps/api/js?sensor=false"></script>
<script src="js/maps.js" type="text/javascript"></script>
<script type="text/javascript">
function initialize()
{
	var mylatlng = new google.maps.LatLng(<?php echo $latitude; ?>, <?php echo $longitude; ?>);
	var centerlatlng = new google.maps.LatLng(<?php echo $lat; ?>, <?php echo $long; ?>);
	var myOptions =
	{
		zoom: <?php echo $zoom; ?>,
		center: centerlatlng,
		disableDefaultUI: true,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);

	google.maps.event.addListener(map, 'click', function() {
		clearActive();
		clearMoved();
	});

	google.maps.event.addListener(map, 'zoom_changed', function() {
		document.getElementById('zoom').value = map.getZoom();
	});

	google.maps.event.addListener(map, 'center_changed', function() {
		var center = map.getCenter();
		
		document.getElementById('lat').value = center.lat();
		document.getElementById// echo "/*$query\n*/";('long').value = center.lng();
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
} // end if(!mobile)

$query = "SELECT
	stations.id,
	stations.callsign,
	stations.parentcall,
	stations.latitude,
	stations.longitude,
	stations.distance,
	stations.rf,
	log.ss,
	log.snq,
	log.seq,
	MAX(log.logtime) as logtime
FROM stations, log
WHERE
	stations.id = log.id AND ";
$query .= "tunerid = $tuner AND ";

foreach($options as $key => $value)
{
	$time = $key;
	break;
}
if(isset($_POST['time']))
{
	$time = $_POST['time'];
}

if($time != 'ALL')
	$query .= "logtime > DATE_ADD(DATE_SUB(NOW(), interval $time), interval 2 HOUR) AND ";

if(isset($_POST['dxonly']))
{
	$query .= "distance > 100 AND ";
}
$query .= "stations.callsign in (
		SELECT distinct callsign from stations )
		GROUP BY(stations.callsign)";

// echo "/*$query\n*/";

$mindistance = 0;
if(isset($_POST['dxonly']))
{
	$mindistance = 100;
}

foreach($options as $key => $value)
{
	$time = $key;
	break;
}
if(isset($_POST['time']))
{
	$time = $_POST['time'];
}

if($time == 'ALL')
	$query = "call GetAllLogInfo($tuner, $mindistance)";
else
	$query = "call GetLogInfo($tuner, $mindistance, $time)";

$stmt = mysql_query($query);

$stations = array();
$i = 0;
while($row = mysql_fetch_assoc($stmt))
{
	$id = $row['id'];
	$callsign = $row['callsign'];
	$parentcall = $row['parentcall'];
	$latitude = $row['latitude'];
	$longitude = $row['longitude'];
	$channel = $row['rf'];
	$ss = $row['ss'];
	$snq = $row['snq'];
	$seq = $row['seq'];
	$time = $row['logtime'];
	$distance = $row['distance'];

	$stations []= $row;
    $title = ($callsign == $parentcall ? $callsign : "$callsign ($parentcall)");
	$title = "$title";

	if(!$mobile)
	{
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
	content:	'$title<br />' +
				'<hr>' +
				'Last received on $time<br />' +
				'Channel: $channel<br />' +
				'Distance: $distance miles<br />' +
				'Most recent scan:<br />' +
				'Signal Strength: $ss<br />' +
				'Signal Quality: $snq<br />' +
				'Symbol Quality: $seq<br />' +
				'<br />' +
				'<a href=\"plot.php?id=$id&tuner=$tuner\" target=\"_blank\">Signal Graph</a><br />' +
				'<a href=\"http://rabbitears.info/market.php?request=station_search&callsign=$callsign#station\" target=\"_blank\">RabbitEars lookup</a>'
});\n";

	echo "markers[$i].click = function() {
// 	map.setCenter(new google.maps.LatLng($latitude, $longitude));
	clearActive();
	active=$i;
	checkMove();
	markers[$i].setZIndex(2);
	infowindows[$i].open(map, markers[$i]);
};\n";

	echo "google.maps.event.addListener(markers[$i], 'click', markers[$i].click);";

	echo "addPoint(markers[$i]);\n";

	echo "\n";
	$i++;
	}
}
if(!$mobile)
{
?>
}
</script>
<?php
} // if(!$mobile)
else
{
?>
<style>
select
{
/* 	width: 320px; */
	font-size: 200%;
}
input
{
	font-size: 200%;
}
label
{
	font-size: 200%;
}
</style>
<?php
}
?>
<!-- <link href="style.css" rel="stylesheet" type="text/css" /> -->
</head>

<body id='body' <?php echo (!$mobile ? "onload='initialize()'" : ''); ?> >
<div>
<form action='<?php phpself(); ?>' method='POST'>
	<input id='zoom' name='zoom' type='hidden' value='<?php echo $zoom; ?>' />
	<input id='lat' name='lat' type='hidden' value='<?php echo $latitude; ?>' />
	<input id='long' name='long' type='hidden' value='<?php echo $longitude; ?>' />
	<select name='tuner'>
<?php

foreach($tuners as $value => $text)
{
	$selected = '';
	if(isset($_POST['tuner']) && $_POST['tuner'] == $value)
	{
		$selected = ' selected=\'true\'';
	}
	echo "<option value='$value'$selected>$text</option>\n";
}
?>
	</select>
	<select name='time'>
<?php
	foreach($options as $value => $text)
	{
		$selected = '';
		if(isset($_POST['time']) && $_POST['time'] == $value)
		{
			$selected = ' selected=\'true\'';
		}
		echo "<option value='$value'$selected>$text</option>\n";
	}
?>
	</select>
	<input type='submit' name='submit' value='Go' /><br />
	<br />
	<label for='dxonly'>Only show DXes</label><input type='checkbox' id='dxonly' name='dxonly' value='dxonly' <?php echo (isset($_POST['dxonly']) ? "checked='checked'" : "" ); ?> />
</form>
</div>
<div id="content">
	<div id="sidebar" <?php echo (!$mobile ? 'style="float: left; width: 200px;"' : '' ); ?> >
		<?php if(!$mobile) echo 'Click text to locate station on map'; ?>
		<ul id="sidebar-list">
<!-- 			<li>Show All</li> -->
<?php
	foreach($stations as $index => $station)
	{
		$callsign = $station['callsign'];
		$distance = $station['distance'];
		$data = "$callsign ($distance miles)";
		$a = "<a href=\"#\" onclick=\"markers[$index].click()\">$data</a>";
		$li = $mobile ? $data : $a;
		echo "<li>$li</li>\n";
	}
?>
		</ul>
	</div>
<?php
if(!$mobile)
{
?>
	<div id="map_canvas" style="width: 80%; height:100%; float: right;"></div>
<?php
}
 ?>

</div>
</body>
</html>
