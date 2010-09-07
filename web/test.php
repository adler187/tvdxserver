<?php include "include/functions.php"; ?>
<?php

if(checkmobile())
{
	echo "hello mobile phone!\n";
}
else
{
	echo "you aren't mobile!\n";
}
?>