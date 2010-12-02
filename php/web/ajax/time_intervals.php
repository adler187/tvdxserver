<?php
include "../include/db.php";

$stmt = mysql_query("select * from time_intervals");

$json = array();

$json["identifier"] = "time_interval";
$json["label"] = "description";

$intervals = array();

while($row = mysql_fetch_assoc($stmt))
{
	$intervals []= $row;
}

$json["items"] = $intervals;

echo json_encode($json);

?> 
