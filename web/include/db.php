<?php
if(!defined($db_included))
{
	$db_included = true;

	$db_host = "mysql.zekesdominion.com";
	$db_username = "dxscan";
	$db_password = "0j3rm1";
	$db_db = "dxscan";


	// added TRUE, 131074 parameters because otherwise stored procedures don't work
	// see http://ubuntuforums.org/showpost.php?p=2110175&postcount=5
	$conn = mysql_connect($db_host, $db_username, $db_password, TRUE, 131074);
	if(!$conn) die("Couldn't connect to host");

	if(!mysql_select_db($db_db)) die("Couldn't select the database");
}
?>