<?php
if(!defined($db_included))
{
	$db_included = true;

	$db_host = "mysql.zekesdominion.com";
	$db_username = "dxscan";
	$db_password = "0j3rm1";
	$db_db = "dxscan";


	$conn = mysql_connect($db_host, $db_username, $db_password);
	if(!$conn) die("Couldn't connect to host");

	if(!mysql_select_db($db_db)) die("Couldn't select the database");
}
?>