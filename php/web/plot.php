<?php include "include/db.php"; ?>

<?php

$start = isset($_GET['start']) ? $_GET['start'] : false;
$end   = isset($_GET['end']) ? $_GET['end'] : false;
$id    = isset($_GET['id']) ? $_GET['id'] : false;
$tuner = isset($_GET['tuner']) ? $_GET['tuner'] : false;

if(!$id)
{
	exit;
}

$tenmins = 600;
$oneday = 86400;

if(!$start)
{
	$start = time() - 7 * $oneday;
}

$query = "select antenna from tuners where id='$tuner'";
$rs = mysql_query($query);
$row = mysql_fetch_assoc($rs);
$description = $row['antenna'];


$query = "select callsign from stations where id='$id'";

$rs = mysql_query($query);

$row = mysql_fetch_assoc($rs);

$callsign = $row['callsign'];

$query =
"select UNIX_TIMESTAMP(logtime) as logtime,
		ss,
		snq,
		seq,
		tunerid
from log
where
	tunerid='$tuner' and
	id='$id' ";
if($start)
{
	$query .= " and unix_timestamp(logtime) > $start ";
}
if($end)
{
	$query .= " and unix_timestamp(logtime) < $end ";
}
$query .= "order by logtime";

$rs = mysql_query($query, $conn);

$maxrows = 24;

if(mysql_num_rows($rs) > $maxrows)
{
	$query =
"select
	date(logtime) as date,
	unix_timestamp(date(logtime)) as logtime,
	floor(avg(ss)) as ss,
	floor(avg(snq)) as snq,
	floor(avg(seq)) as seq,
	tunerid
from log
where
	tunerid='$tuner' and
	id='$id' ";
if($start)
{
	$query .= " and unix_timestamp(logtime) > $start ";
}
if($end)
{
	$query .= " and unix_timestamp(logtime) < $end ";
}
$query .=  "group by date(logtime)";


$rs = mysql_query($query, $conn);
}


// Standard inclusions
include("include/pChart/pData.class");
include("include/pChart/pChart.class");

// Dataset definition   
$DataSet = new pData;

$series = array();
$series []= 'SignalSeries';
$series []= 'SNRSeries';
$series []= 'SymbolSeries';

$titles = array();
$titles []= 'Signal Strength';
$titles []= 'SNR';
$titles []= 'Symbol Quality';

$xseries = 'TimeSeries';

$prev = false;
$prevday = false;
$prevmonth = false;

$points = 0;
$prevmonth = 0;
$pointgap = ceil(mysql_num_rows($rs) / 7);

$dateformat= 'M d';

function add_new_month_point($time, $data)
{
	global $DataSet;
	global $xseries;
	global $series;
	global $points;
	global $prevmonth;
	global $pointgap;
	global $dateformat;

	if($points - $prevmonth > $pointgap)
	{
		$DataSet->AddPoint(date('M d', $time), $xseries);
		$prevmonth = $points;
	}
	else
	{
		$DataSet->AddPoint('', $xseries);
	}
	
	$prevday = date('d', $time);
	for($i = 0; $i < count($series); $i++)
	{
		$DataSet->AddPoint($data, $series[$i]);
	}
	
	$points++;
}

while($row = mysql_fetch_assoc($rs))
{
	$logtime = $row['logtime'];
	
	$ss = $row['ss'];
	$snr = $row['snq'];
	$sym = $row['seq'];

	$data = array();
	$data []= $ss;
	$data []= $snr;
	$data []= $sym;

	if(!$prev)
	{

		$DataSet->AddPoint(date($dateformat, $logtime), $xseries);
		for($i = 0; $i < count($series); $i++)
		{
			$DataSet->AddPoint($data[$i], $series[$i]);
		}

		$prevday = date('d', $logtime);
		$prevmonth = $points;
	}
	else
	{
		$timediff = $logtime - $prev;
		
		if($timediff > $tenmins)
		{
			if($timediff > $oneday)
			{
				$numtics = floor(($logtime - $prev) / $oneday);
				$added = 0;
				
				for($i = 0; $i < $numtics; $i++)
				{
					$time = $prev + ($oneday * ($i + 1));
					
					if(date('d', $time) != date('d', $logtime))
					{
						add_new_month_point($time, '');
						$added++;
					}
				}
				if(!$added)
				{
					$DataSet->AddPoint('', $xseries);
				
					for($i = 0; $i < count($series); $i++)
					{
						$DataSet->AddPoint('', $series[$i]);
					}

					$points++;
				}
			}
			else
			{
// 				$numtics = ($logtime - $prev) / $tenmins;
// 				for($i = 0; $i < $numtics; $i++)
// 				{
// 					$time = $prev + ($tenmins * ($i + 1));
// 					$DataSet->AddPoint(date('', $time), $xseries);
// 					$DataSet->AddPoint('', $yseries);
// 				}
			}
		}
		if($prevday != date('d', $logtime))
		{
			$prevday = date('d', $logtime);
			$DataSet->AddPoint(date($dateformat, $logtime), $xseries);
		}
		else
		{
			$DataSet->AddPoint('', $xseries);
		}
		for($i = 0; $i < count($series); $i++)
		{
			$DataSet->AddPoint($data[$i], $series[$i]);
		}
	}
	$points++;
	$prev = $logtime;
}

// $DataSet->AddSeries($xseries);
$DataSet->SetAbsciseLabelSeries($xseries);
for($i = 0; $i < count($series); $i++)
{
	$DataSet->AddSeries($series[$i]);
	$DataSet->SetSeriesName($titles[$i], $series[$i]);
}

// Initialise the graph  
$Test = new pChart(700,230);  
$Test->setFontProperties("include/Fonts/tahoma.ttf",10);  
$Test->setGraphArea(40,30,680,200);  
$Test->drawGraphArea(252,252,252);  
$Test->drawScale($DataSet->GetData(),$DataSet->GetDataDescription(),SCALE_NORMAL,150,150,150,TRUE,0,2);  
$Test->drawGrid(4,TRUE,230,230,230,255);  

// Draw the line graph  
$Test->drawLineGraph($DataSet->GetData(),$DataSet->GetDataDescription());
$Test->drawPlotGraph($DataSet->GetData(),$DataSet->GetDataDescription(),3,2,255,255,255);

// Finish the graph
$Test->setFontProperties("include/Fonts/tahoma.ttf",8);
$Test->drawLegend(45,35,$DataSet->GetDataDescription(),255,255,255);
$Test->setFontProperties("include/Fonts/tahoma.ttf",10);
$Test->drawTitle(60,22,"$callsign - $description",50,50,50,585);

$img = "temp/".rand().".png";
$Test->Render($img);

?>

<html>
<body>
<img src='<?php echo $img; ?>' />
</body>
</html>