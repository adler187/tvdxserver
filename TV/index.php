<?php
include "config.php";
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<!-- This page is almost a direct copy of http://uwmike.com/maps/manhattan2/ -->
<!-- I'm not a web-whiz! -KB8U -->
<head>
<title>Stations received by <?php echo $user; ?></title>
<script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=<?php echo $key; ?>" type="text/javascript"></script>
<script src="map_data.js" type="text/javascript"></script>
<script src="labeled_marker.js" type="text/javascript"></script>
<script src="map_functions.js" type="text/javascript"></script>
<link href="style.css" rel="stylesheet" type="text/css" />
</head>
<body class="sidebar-right">
<div id="toolbar">
<h1> TV stations received by <?php echo "$user in $city, $state"; ?></h1>
</h1>
<script src="time.js" type="text/javascript"></script>
<img src="TV/green_dot.png" width='15' height='15' />Strong signal
<img src="TV/yellow_dot.png" width='15' height='15' />Medium signal
<img src="TV/red_dot.png" width='15' height='15' />Weak signal
<img src="TV/black_dot.png" width='15' height='15' />Detected in last 48 hours, but not currently<br>
Zoom in for more stations.  Click a call sign for more details.
This page updates every five minutes.
<ul id="options">
<li><a href="/cricket/grapher.cgi?target=%2FTV">Click here for graphs of signal strength for all stations ever received</a></li>
</ul>
</div>
<div id="content">
<div id="map-wrapper">
<div id="map"></div>
</div>
<div id="sidebar">
Click text to locate station on map
<ul id="sidebar-list">
</ul>
</div>
</div>
</body>
</html>
