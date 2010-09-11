<?php include "include/config.php"; ?>
<?php include "include/db.php"; ?>
<?php include "include/functions.php"; ?>

<?php

$time_intervals = json_decode(file_get_contents("http://".$_SERVER["HTTP_HOST"]."/ajax/time_intervals.php"));

$time = $time_intervals->items[0];

$tuners = json_decode(file_get_contents("http://".$_SERVER["HTTP_HOST"]."/ajax/tuners.php"));

$tuner = $tuners->items[0];

if(isset($_POST['tuner']))
{
	for($i = 0; $i < count($tuners->items); $i++)
	{
		$tuner = $tuners->items[$i];
		if($tuner->id == $_POST['tuner'])
			break;
	}
}

if(isset($_POST['time']))
{
	for($i = 0; $i < count($time_intervals->items); $i++)
	{
		$time = $time_intervals->items[$i];
		if($time->time_interval == $_POST['time'])
			break;
	}
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

<link rel="stylesheet" type="text/css" href="http://ajax.googleapis.com/ajax/libs/dojo/1.5/dijit/themes/claro/claro.css" />
<link rel="stylesheet" type="text/css" href="Simpl.css" />
<script src="http://ajax.googleapis.com/ajax/libs/dojo/1.5/dojo/dojo.xd.js" type="text/javascript" djConfig="parseOnLoad: true"></script>
<script type='text/javascript'>
	dojo.require("dojo.data.ItemFileReadStore");
	dojo.require("dijit.form.FilteringSelect");
</script>
<?php
if(!$mobile)
{
?>
<meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
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
		document.getElementById('long').value = center.lng();
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
}

$mindistance = 0;
if(isset($_POST['dxonly']))
{
	$mindistance = 100;
}

if($time->time_interval == 'ALL')
	$query = "call GetAllLogInfo({$tuner->id}, $mindistance)";
else
	$query = "call GetLogInfo({$tuner->id}, $mindistance, {$time->time_interval})";

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
	$logtime = $row['logtime'];
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
				'Last received on $logtime<br />' +
				'Channel: $channel<br />' +
				'Distance: $distance miles<br />' +
				'Most recent scan:<br />' +
				'Signal Strength: $ss<br />' +
				'Signal Quality: $snq<br />' +
				'Symbol Quality: $seq<br />' +
				'<br />' +
				'<a href=\"plot.php?id=$id&tuner={$tuner->id}\" target=\"_blank\">Signal Graph</a><br />' +
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
<!--<style>
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
</style>-->
<?php
}
?>
</head>

<body id='body' <?php echo (!$mobile ? "onload='initialize()'" : ''); ?> class='claro' >
<div dojoType="dojo.data.ItemFileReadStore" url="ajax/time_intervals.php" jsId="timeIntervalStore"></div>
<div dojoType="dojo.data.ItemFileReadStore" url="ajax/tuners.php" jsId="tunerStore"></div>

<div class="ColumnWrapper" style="height: 100%">
	<div class="ColumnOneQuarter" style="height: 100%">
		<form action='<?php phpself(); ?>' method='POST'>
			<input id='zoom' name='zoom' type='hidden' value='<?php echo $zoom; ?>' />
			<input id='lat' name='lat' type='hidden' value='<?php echo $latitude; ?>' />
			<input id='long' name='long' type='hidden' value='<?php echo $longitude; ?>' />
			<input dojoType="dijit.form.FilteringSelect" name='tuner' value='<?php echo $tuner->id ?>' displayValue='<?php echo $tuner->tunerid ?>' store="tunerStore" searchAttr="tunerid" />
			<input dojoType="dijit.form.FilteringSelect" name='time' value='<?php echo $time->time_interval ?>' displayValue='<?php echo $time->description ?>' store="timeIntervalStore" searchAttr="description" />

			<input type='submit' name='submit' value='Go' /><br />
			<br />
			<label for='dxonly' style='width: auto'>Only show DXes</label><input type='checkbox' id='dxonly' name='dxonly' value='dxonly' <?php echo (isset($_POST['dxonly']) ? "checked='checked'" : "" ); ?> />
		</form>
		<?php if(!$mobile) echo 'Click text to locate station on map'; ?>
		<ul id="sidebar-list" style="height: 100%; overflow: auto">
<?php
	foreach($stations as $index => $station)
	{
		$callsign = $station['callsign'];
		$distance = $station['distance'];
		$data = "$callsign&nbsp;($distance&nbsp;miles)";
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
    <div class="ColumnThreeQuarters" style="height: 100%">
		<div id="map_canvas" style="height: 100%"></div>
	</div>
<?php
}
?>
</div>
</body>
</html>
