<?php
include "../include/db.php";

$stmt = mysql_query("select id, tunerid from tuners");

$json = array();

$json["identifier"] = "id";
$json["label"] = "tunerid";

$intervals = array();

while($row = mysql_fetch_assoc($stmt))
{
	$intervals []= $row;
}

$json["items"] = $intervals;

echo json_encode($json);

?> 
