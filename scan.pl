#!/usr/bin/env perl

# scan tuner on Silicon Dust HDHomeRun to collect TV station channel, callsign
# and strength.  Locate station using FCC web site.  Write to log file

use List::MoreUtils qw(any none);
use Date::Format;
use Config::IniFiles;
use LWP::Simple;
use Math::Trig qw(great_circle_distance deg2rad);

use DBI;

use constant false => 0;
use constant true  => 1;

my %ini;
tie %ini, 'Config::IniFiles', ( -file => 'config.ini' );

# program used to interface with tuner
$CONFIG_PROG = $ini{'cfg'}{'prog'};

@tuner_list = split(/\s+/, $ini{'cfg'}{'tuners'});

@tuners = ();
foreach $tuner (@tuner_list)
{
	@device_list = split(/\s+/, $ini{$tuner}{'tuners'});
	foreach $device (@device_list)
	{
		push @tuners, {'tunerid' => $ini{$tuner}{'tunerid'}, 'tuner' => $device};
	}
}
# tuner ID; can use FFFFFFFF if it's the only one on network
$TUNER_ID = $tuners[0]{'tunerid'};

# which tuner to scan
$TUNER = $tuners[0]{'tuner'};

# location of tuner
$TUNER_LAT = $ini{'info'}{'latitude'};
$TUNER_LON = $ini{'info'}{'longitude'};

# Distance to be considered a "DX"
$DX_DISTANCE = 100;

$FCC_URL = 'http://www.fcc.gov/fcc-bin/tvq?call=$callsign&chan=$channel&cha2=$channel&list=4&size=9';
# output is like:
#|WWJ-TV      |-         |DT |44  |ND  |0                   |-  |-  |LIC    |DETROIT                  |MI |US |BLCDT  -19990720LH  |200.   kW |-         |323.0   |-       |72123      |N |42 |26 |52.00 |W |83  |10 |23.00 |CBS BROADCASTING INC.                                                       |   0.00 km |   0.00 mi |  0.00 deg |523.   m|H       |32850 |-       |1003429 |321.    |

$database = $ini{'db'}{'database'};
$hostname = $ini{'db'}{'host'};
$port = $ini{'db'}{'port'};
$user = $ini{'db'}{'username'};
$password = $ini{'db'}{'pass'};

$dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";

$drh = DBI->install_driver("mysql");

$loop = ($ini{'cfg'}{'loop'} eq "true" ? 1 : '');

$wait = $ini{'cfg'}{'wait'};

$wait = ($wait ? $wait : 60);
$wait_time = 0;

if(defined($ini{'cfg'}{'latitude'}) && defined($ini{'cfg'}{'longitude'}))
{
	my $latitude = $ini{'cfg'}{'latitude'};
	my $longitude = $ini{'cfg'}{'longitude'};

	@mylocation = ( deg2rad($longitude), deg2rad(90 - $latitude) );
}

$log = true;
open LOG, ">>tuner-$TUNER_ID-".substr($TUNER, -2, 1).".log" or $log = false;

# remove buffering for LOG
$| = 1;

$SIG{INT} = \&cleanup;
$SIG{TERM} = \&cleanup;

##### main #####
do
{
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

	$conn = DBI->connect($dsn, $user, $password);
	my $start_time = time();
	
	#If we couldn't connect, just loop and try again (after sleeping of course...)	
	if(!$conn)
	{
		print "Couldn't connect, sleep and loop again\n";
	}
	else
	{		
		# log all output from scan, note when calls and all-time new calls are found
		my $file_time = time2str('%Y-%m-%d %T',time);
		
		# scan tuner
		open SCAN, "$CONFIG_PROG $TUNER_ID scan $TUNER |" or die "can't run scan";

		my ($id, $tsid, $freq, $channel, $modulation, $strength, $sig_noise, $symbol_err, $program, $number, $callsign, $latitude, $longitude, $distance, $new);
		my (%callsign, %modulation, %strength, %sig_noise, %number, %last_seen);
		while($line = <SCAN>)
		{
			print $line;
			if($line =~ /^SCANNING:\s+(\d+)\s+\(us-bcast:(\d+)?\)/)
			{
				$freq = $1;
				$channel = $2;
				$modulation = '';
				$strength = '';
				$sig_noise = '';
				$symbol_err = '';
				$program = '';
				$number = '';
				$callsign = '';
				$tsid = '';
			}
			elsif($line =~ /^LOCK:\s+(\S+)\s+\(ss=(\d+)\s+snq=(\d+)\s+seq=(\d+)\)/)
			{
				$modulation = $1;
				$strength   = $2;
				$sig_noise  = $3;
				$symbol_err = $4;
			}
			elsif($line =~ /^TSID:\s+(0x(?:\d|[ABCDEF])+)/)
			{
				$tsid = $1;
			}
			elsif($line =~ /^PROGRAM\s+(\d+):\s+(\S+)(?:\s+(\S+))?/)
			{
				# ignore all other PROGRAM: lines
				next if $program;
				
				$program = $1;
				@num_part = split(/[.]/, $2);
				$number = $num_part[0];
				$callsign = $3;
			}
			
			if ($program)
			{
				if($tsid eq '0x0001')
				{
					log_output("Received a station with an invalid tsid $tsid on rf channel $channel, display channel $number at $file_time");
					log_output("This is most likely a translator that has not been properly set up correctly");
					log_output("You can add this station manually, but note that the tsid might change in the future when it gets set properly and will be re-added");
					log_output("Signal: $strength, SNR: $sig_noise, SER: $symbol_err");
					next;
				}
				
				$rs = $conn->prepare("select callsign, distance, id from stations where tsid='$tsid' and rf=$channel");
				$rs->execute();
				@row = $rs->fetchrow_array();
				$rs->finish();
				
				if($row[0] ne "")
				{
					$callsign = $row[0];
					$distance = $row[1];
					$id = $row[2];

					$new = 0;
				}
				else
				{
					$new = 1;
					# if callsign is like KTTCDT, remove DT
					# make sure we don't match KTTC-DT, which would be matched by next if, but end up with KTTC- here
					if(length($callsign) > 4 && $callsign =~ /\wDT$/)
					{
						$callsign = substr($callsign, 0, length($callsign)-2);
					}
					# else check if regex
					elsif($callsign =~ /^((?:[CWKX][A-Z]{2,3})|(?:[KW]\d{1,2}[A-Z]{2}))/)
					{
						$callsign = $1;
					}
					# some stations don't use callsign (like tpt), do lookup on rabbitears
					else
					{
						log_output("getting callsign from rabbitears");
						$url="http://rabbitears.info/oddsandends.php?request=tsid";
						$html=get($url);
						if($html =~ /<td>$tsid&nbsp;<\/td><td><a href=(?:'|")\/market\.php\?request=station_search&callsign=\d+(?:'|")>((?:[CWKX][A-Z]{2,3})|(?:[KW]\d{1,2}[A-Z]{2}))(?:-(?:(?:TV)|(?:DT)))?<\/a>&nbsp;<\/td><td align='right'>(\d+)(?:&nbsp;)*<\/td><td align='right'>(\d+)/)
						{
							$callsign = $1;
							$realdisp = $2;
							$realrf = $3;
							if($realrf != $channel || $realdisp != $number)
							{
								log_output("Found a translator of $callsign on channel $channel at $file_time, add manually");
								log_output("Signal: $strength, SNR: $sig_noise, SER: $symbol_err");
								next;
							}
						}
						else
						{
							log_output("Couldn't find callsign for tsid $tsid on channel $channel, display channel $number at $file_time, add manually");
							log_output("Signal: $strength, SNR: $sig_noise, SER: $symbol_err");
							next;
						}
					}
					
					# facid: facility id number
					# call: callsign of station
					# chan: lower bound on channel number to search
					# cha2: upper bound on channel number to search
					# type: (3) Only licenced stations, no CPs or pending aps
					# list: (4) Text ouput, pipe delimited
					my $url = "http://www.fcc.gov/fcc-bin/tvq?call=$callsign&chan=$channel&cha2=$channel&list=4";
					my @lines = split(/\n/, get($url));
					
					if(scalar(@lines) == 0)
					{
						log_output("Found a translator of $callsign on channel $channel at $file_time, add manually");
						log_output("Signal: $strength, SNR: $sig_noise, SER: $symbol_err");
						next;
					}
					
					foreach $line (@lines)
					{
						my @tokens = split(/\|/, $line);
						for($i=0; $i < scalar(@tokens); $i++)
						{
							$tokens[$i] = rtrim($tokens[$i]);
						}
						my
						(
							$blank,
							$call,
							$unused,
							$lic_type,
							$chan,
							$app_type,
							$unused,
							$tv_zone,
							$unused,
							$atenna_type,
							$city,
							$state,
							$country,
							$fileno,
							$erp,
							$unused,
							$haat,
							$unused,
							$facid,
							$lat,
							$lat_deg,
							$lat_min,
							$lat_sec,
							$long,
							$long_deg,
							$long_min,
							$long_sec,
							$licensee,
							$km,
							$mi,
							$azimuth,
							$amsl,
							$polarization,
							$antenna_id,
							$rotation,
							$asrn,
							$agl
						)  = @tokens;

						# should be not needed with type=3 in fcc query
						next if (rtrim($lic_type) =~ /STA/);
						
						$latitude = ($lat_deg + $lat_min/60 + $lat_sec/3600) * ($lat eq 'S' ? -1 : 1);
						$longitude = ($long_deg + $long_min/60 + $long_sec/3600) * ($long eq 'W' ? -1 : 1);
						
						if(defined(@mylocation))
						{
							my @location = ( deg2rad($longitude), deg2rad(90 - $latitude) );
							
							$distance = great_circle_distance(@mylocation, @location, 6378) * 0.621371192;
						}
						else
						{
							$distance = "NULL";
						}

						last if(rtrim($lic_type) =~ /LIC/);
					}
										
					print "$callsign: $latitude, $longitude, $distance\n";
					
					$rs = $conn->prepare("insert into stations(tsid, callsign, parentcall, rf, display, latitude, longitude, distance) values('$tsid', '$callsign', '$callsign', $channel, $number, $latitude, $longitude, $distance)");
					$rs->execute();
					$rs->finish();

					$rs = $conn->prepare("select last_insert_id()");
					$rs->execute();
					@row = $rs->fetchrow_array();
					$id = $row[0];
					$rs->finish();
				}
				
				# Only log the station if it is new, a DX, or is around the top of the hour (so once per hour).
				if(1 || $distance > $DX_DISTANCE || $new || $min > 55 || $min < 5)
				{
					if($id == 0)
					{
						log_output("Failed to insert station $callsign with tsid($tsid) on channel($channel, $number)");
						log_output("Had Strength($strength), SNR($sig_noise), Symbol($symbol_err) at $file_time");
					}
					else
					{
						$rs = $conn->prepare("insert into log values($id, $strength, $sig_noise, $symbol_err, '$file_time')");
						$rs->execute();
						$rs->finish();
					}
				}
			}
		}

	# 	# get old locations from cache file
	# 	open CACHE, $CACHE_FILE;
	# 	while(<CACHE>) { eval }
	# 	close CACHE;
	# 
	# 	# prune entries older than two days (172800 seconds)
	# 	foreach my $callsign (keys %lat)
	# 	{
	# 		if ($record_age{$callsign}+172800 < time)
	# 		{
	# 			delete $channel{$callsign};
	# 			delete $location{$callsign};
	# 			delete $lat{$callsign};
	# 			delete $lon{$callsign};
	# 			delete $dx_km{$callsign};
	# 			delete $azimuth{$callsign};
	# 			delete $erp{$callsign};
	# 			delete $haat{$callsign};
	# 			delete $facility_id{$callsign};
	# 			delete $owner{$callsign};
	# 			delete $rcamsl{$callsign};
	# 			delete $record_age{$callsign};
	# 		}
	# 	}
	# 
	# 	# get all callsigns detected in any previous scan
	# 	my @cr_callsigns;
	# 	foreach my $file (glob "$CRICKET_RAW_DIR/*")
	# 	{
	# 		# get callsign from filename on end of path
	# 		my @path = split(/\//, $file);
	# 		my $cr_callsign = $path[$#path];
	# 		
	# 		next if $cr_callsign !~ /^([cwkx][a-z]{2,3})/; # must be a callsign
	# 		
	# 		push @cr_callsigns,$cr_callsign;
	# 	}
	# 
	# 	# get all callsigns with a cricket config
	# 	my @cc_callsigns;
	# 	foreach my $dir (glob "$CRICKET_CONFIG/*")
	# 	{
	# 		# get callsign from dir on end of path
	# 		my @path = split(/\//,$dir);
	# 		my $cc_callsign = $path[$#path];
	# 		
	# 		next if $cc_callsign !~ /^([CWKX][A-Z]{2,3})/; # must be a callsign
	# 		push @cc_callsigns,$cc_callsign;
	# 	}
	# 
	# 	# Write zeros for undetected stations in $CRICKET_RAW_DIR
	# 	foreach my $cr_callsign (@cr_callsigns)
	# 	{
	# 		if (none { $_ eq uc $cr_callsign } (values %callsign))
	# 		{
	# 			open NO_SIGNAL, "> $CRICKET_RAW_DIR/$cr_callsign" or die "can't open $CRICKET_RAW_DIR/$cr_callsign";
	# 			print NO_SIGNAL "0\n0\n";
	# 			close NO_SIGNAL;
	# 		}
	# 	}
	# 
	# 	# Write cricket raw data and find current location, etc. from FCC database
	# 	foreach $channel (sort keys %callsign)
	# 	{
	# 		my $callsign = $callsign{$channel};
	# 
	# 		my $raw_file = "$CRICKET_RAW_DIR/" . lc $callsign;
	# 		open RAW_DATA, "> $raw_file" or die "can't write to $raw_file";
	# 		print RAW_DATA "$strength{$channel}\n$sig_noise{$channel}\n";
	# 		close RAW_DATA;
	# 
	# 		# store last seen time, strength and quality for google maps display
	# 		my $last_seen_file = "$LAST_SEEN_DIR/" . lc $callsign;
	# 		open LAST_SEEN, "> $last_seen_file" or die "can't write to $last_seen_file";
	# 		print LAST_SEEN time;
	# 		print LAST_SEEN " $strength{$channel} $sig_noise{$channel}\n";
	# 		close LAST_SEEN;
	# 
	# 		# Don't go to FCC if station information was retrieved from cache
	# 		if (! exists $lat{$callsign})
	# 		{
	# 			my $wget = "$WGET '$FCC_URL"."call=$callsign&chan=$channel&cha2=$channel&list=4&size=9'";
	# 			
	# 	#      print SCAN_FILE "##### Trying $wget\n";
	# 			open FCC, "$wget |" or die "can't open $wget |";
	# 			while (<FCC>)
	# 			{
	# 				next if $_ !~ /^\|/; # line must begin with |
	# 				# see http://www.fcc.gov/mb/audio/am_fm_tv_textlist_key.txt
	# 				my ($blank,$call,$not_used,$service,$fcc_channel,$antenna,$offset,$tv_zone,$not_used,$tv_status,$city,$state,$country,$file_number,$erp,$not_used,$haat,$not_used,$facility_id,$n_or_s,$lat_deg,$lat_min,$lat_sec,$w_or_e,$lon_deg,$lon_min,$lon_sec,$greedy_corporate_overlord,$dx_km,$dx_miles,$azimuth,$rcamsl,$polarization,$ant_id,$ant_rot,$ant_struct_number,$archagl) = split /\s*\|/,$_;
	# 				$call =~ s/\-TV$//; # remove -TV from end of call from FCC site
	# 				# FCC returns longer matches for short calls, match must be exact
	# 				next if (uc $call ne uc $callsign);
	# 				# remove white space from position data, erp, haat, facility id, state
	# 				map { $_ =~ s/\s+//g; } ($n_or_s, $lat_deg, $lat_min, $lat_sec, $w_or_e, $lon_deg, $lon_min, $lon_sec, $erp, $haat, $facility_id, $state);
	# 				# remove extra white space from rcamsl
	# 				$rcamsl =~ s/\s+/ /;
	# 				# clean up erp
	# 				$erp =~ s/kW/ kW/;
	# 				$erp =~ s/\. kW/.0 kW/;
	# 				# remove white space at end of owner
	# 				$greedy_corporate_overlord =~ s/\s+$//;
	# 				# remove white space at end of city
	# 				$city =~ s/\s+$//;
	# 
	# 				$location{$callsign} = "$city, $state";
	# 
	# 				my $lat_decimal = $lat_deg + $lat_min/60 + $lat_sec/3600;
	# 				$lat_decimal = -1 * $lat_decimal if $n_or_s eq 'S';
	# 				$lat{$callsign} = $lat_decimal;
	# 				
	# 				my $lon_decimal = $lon_deg + $lon_min/60 + $lon_sec/3600;
	# 				$lon_decimal = -1 * $lon_decimal if $w_or_e eq 'W';
	# 				$lon{$callsign} = $lon_decimal;
	# 
	# 				($dx_km{$callsign}, $azimuth{$callsign}) = dist("$lat_decimal $lon_decimal","$TUNER_LAT $TUNER_LON");
	# 
	# 				$channel{$callsign} = $channel;
	# 				$erp{$callsign} = $erp;
	# 				$haat{$callsign} = $haat;
	# 				$facility_id{$callsign} = $facility_id;
	# 				$owner{$callsign} = $greedy_corporate_overlord;
	# 				$rcamsl{$callsign} = $rcamsl;
	# 				$record_age{$callsign} = time;
	# 			}
	# 		}
	# 	}
	# 
	# 	# update cache file
	# 	open CACHE_WRITE, ">$CACHE_FILE" or die "can't write to $CACHE_FILE";
	# 	foreach my $callsign (keys %record_age)
	# 	{
	# 		# prepare to save marketing channel number (from tuner) along with FCC data
	# 		if (defined $number{$channel{$callsign}})
	# 		{
	# 			$number{$callsign} = $number{$channel{$callsign}};
	# 		}
	# 
	# 		print CACHE_WRITE '$channel{'.$callsign."} = '".$channel{$callsign}."';\n";
	# 		print CACHE_WRITE '$number{'.$callsign."} = '".$number{$callsign}."';\n";
	# 		print CACHE_WRITE '$location{'.$callsign."} = '".$location{$callsign}."';\n";
	# 		print CACHE_WRITE '$lat{'.$callsign."} = '".$lat{$callsign}."';\n";
	# 		print CACHE_WRITE '$lon{'.$callsign."} = '".$lon{$callsign}."';\n";
	# 		print CACHE_WRITE '$dx_km{'.$callsign."} = '".$dx_km{$callsign}."';\n";
	# 		print CACHE_WRITE '$azimuth{'.$callsign."} = '".$azimuth{$callsign}."';\n";
	# 		print CACHE_WRITE '$erp{'.$callsign."} = '".$erp{$callsign}."';\n";
	# 		print CACHE_WRITE '$haat{'.$callsign."} = '".$haat{$callsign}."';\n";
	# 		print CACHE_WRITE '$facility_id{'.$callsign."} = '".$facility_id{$callsign}."';\n";
	# 		print CACHE_WRITE '$owner{'.$callsign."} = '".$owner{$callsign}."';\n";
	# 		print CACHE_WRITE '$rcamsl{'.$callsign."} = '".$rcamsl{$callsign}."';\n";
	# 		print CACHE_WRITE '$record_age{'.$callsign."} = ".$record_age{$callsign}.";\n";
	# 	}
	# 	close CACHE_WRITE;
	# 
	# 	# create new cricket config Target files for all-time new calls
	# 	my $need_to_compile = 0; # flag to indicate cricket-compile needs to run
	# 	foreach my $callsign (keys %channel)
	# 	{
	# 		if (! scalar grep { $_ eq $callsign } (@cc_callsigns))
	# 		{
	# 	#      print SCAN_FILE "##### first-ever reception of $callsign\n";
	# 			`mkdir $CRICKET_CONFIG/$callsign`;
	# 			open NEW_TARGET, "> $CRICKET_CONFIG/$callsign/Targets";
	# 			print NEW_TARGET <<EOTARGET;
	# target --default--
	# directory-desc = "Physical channel $channel{$callsign}, $location{$callsign}, $dx_km{$callsign} km, Azimuth $azimuth{$callsign}\&deg $erp{$callsign}, $rcamsl{$callsign}"
	# target $callsign
	# target-type = HDTV
	# display-name = "$callsign"
	# short-desc = "$callsign signal statistics"
	# EOTARGET
	# 		close NEW_TARGET;
	# 		$need_to_compile = 1;
	# 		}
	# 	}
	# # 	`/usr/bin/cricket-compile` if $need_to_compile;
	# 
	# 
	# 	my %strength_color;	# four color coded categories of strength (zoom >= 8)
	# 	# key is "city, state", used to show just one call when zoom < 8
	# 	my (%strongest_strength_in, %strongest_call, %color_of_strongest_in);
	# 	my %color_of_strongest_in;
	# 
	# 	# first, the stations that are currently being received.
	# 	foreach my $channel (keys %strength)
	# 	{
	# 		my $lc_callsign = lc $callsign{$channel};
	# 		my $callsign = uc $lc_callsign;
	# 		next unless ($lat{$callsign} && $lon{$callsign}); # skip missing values
	# 		my $icon_color = 'red'    if $strength{$channel} >= 0;
	# 		$icon_color = 'yellow' if $strength{$channel} > 74;
	# 		$icon_color = 'green'  if $strength{$channel} > 84;
	# 
	# 		push @{$strength_color{$icon_color}},$callsign;
	# 
	# 		# save strongest station in a city (display only that one at zoom < 8)
	# 		if ($strength{$channel} > $strongest_strength_in{$location{$callsign}})
	# 		{
	# 			$strongest_strength_in{$location{$callsign}} = $strength{$channel};
	# 			$strongest_call_in{$location{$callsign}} = $callsign;
	# 			$color_of_strongest_in{$location{$callsign}} = $icon_color;
	# 		}
	# 	}
	# 
	# 	# second, the stations that are not currently being received but were
	# 	# within the last 48 hours.  These are colored black.
	# 	my $now = time;
	# 	foreach my $last_seen_call_file (glob "$LAST_SEEN_DIR/*")
	# 	{
	# 		my @path = split /\//,$last_seen_call_file; # file name is callsign
	# 		my $lc_last_seen_call = $path[$#path];       # at end of path
	# 		my $uc_last_seen_call = uc $lc_last_seen_call;
	# 		next if $lc_last_seen_call !~ /^([cwkx][a-z]{2,3})/; # must be a callsign
	# 
	# 		open LAST_SEEN, $last_seen_call_file or die "can't open $last_seen_call_file";
	# 		my ($epoch,$strength,$sn) = split /\s+/,(<LAST_SEEN>);
	# 		$last_seen{$lc_last_seen_call} = $epoch;
	# 		close LAST_SEEN;
	# 
	# 		next if $epoch + 176800 < $now;  # don't show calls > 2 days old
	# 		next if (! defined $owner{$uc_last_seen_call}); #skip if fcc lookup failed
	# 		next if ($owner{$uc_last_seen_call} eq '');
	# 		# skip stations that are currently being received
	# 		next if any {$_ eq $uc_last_seen_call} (values %callsign);
	# 		push @{$strength_color{'black'}},$uc_last_seen_call;
	# 
	# 		# save strongest station in a city unless there's a call currently coming in
	# 		if ( exists $color_of_strongest_in{$location{$uc_last_seen_call}} && $color_of_strongest_in{$location{$uc_last_seen_call}} ne 'black') { next }
	# 		
	# 		if ($strength > $strongest_strength_in{$location{$uc_last_seen_call}})
	# 		{
	# 			$strongest_strength_in{$location{$uc_last_seen_call}} = $strength;
	# 			$strongest_call_in{$location{$uc_last_seen_call}} = $uc_last_seen_call; 
	# 			$color_of_strongest_in{$location{$uc_last_seen_call}} = 'black';
	# 		}
	# 	}
	# 
	# 	open JS_DATA, ">$JS_DATA" or die "can't append to $JS_DATA";
	# 	foreach my $icon_color (qw (black red yellow green))
	# 	{
	# 		# data for zoom levels < 8 (show only the strongest callsign per city)
	# 		print JS_DATA "var $icon_color"."_strongest_markers = [\n";
	# 		foreach my $city (keys %color_of_strongest_in)
	# 		{
	# 			next if ($color_of_strongest_in{$city} ne $icon_color);
	# 			my $callsign = $strongest_call_in{$city};
	# 			print JS_DATA "  {\n";
	# 			print JS_DATA "    'call':'$callsign',\n";
	# 			print JS_DATA "    'latitude':$lat{$callsign},\n";
	# 			print JS_DATA "    'longitude':$lon{$callsign},\n";
	# 			print JS_DATA "    'info':'RF channel $channel{$callsign}<br>Virtual channel $number{$callsign}<br>$location{$callsign}<br>DX: $dx_km{$callsign} km<br>Azimuth: $azimuth{$callsign}\&deg<br>ERP $erp{$callsign}<br>RCAMSL $rcamsl{$callsign}<br>";
	# 			if ($icon_color eq 'black')
	# 			{
	# 				print JS_DATA "last in: ",time2str('%b %e %H:%M %Z',$last_seen{lc $callsign});
	# 				print JS_DATA '<br>';
	# 			}
	# 			print JS_DATA "',\n";
	# 			print JS_DATA "    'graph':'http://kb8u.ham-radio-op.net/cricket/grapher.cgi?target=%2FTV%2F$callsign%2F" . lc $callsign . ";view=signal_info;ranges=d%3Aw%3Am%3Ay',\n";
	# 			print JS_DATA "    'strongest':1\n";
	# 			print JS_DATA "  },\n";
	# 		}
	# 		print JS_DATA "]\n";
	# 
	# 		# data for zoom levels >= 8 (shows all icons)
	# 		print JS_DATA "var $icon_color"."_markers = [\n";
	# 		foreach my $callsign (@{$strength_color{$icon_color}})
	# 		{
	# 			my $lc_callsign = lc $callsign;
	# 			print JS_DATA "  {\n";
	# 			print JS_DATA "    'call':'$callsign',\n";
	# 			print JS_DATA "    'latitude':$lat{$callsign},\n";
	# 			print JS_DATA "    'longitude':$lon{$callsign},\n";
	# 			print JS_DATA "    'info':'RF channel $channel{$callsign}<br>Virtual channel $number{$callsign}<br>$location{$callsign}<br>DX: $dx_km{$callsign} km<br>Azimuth: $azimuth{$callsign}\&deg<br>ERP $erp{$callsign}<br>RCAMSL $rcamsl{$callsign}<br>";
	# 			if ($icon_color eq 'black')
	# 			{
	# 				print JS_DATA "last in: ",scalar localtime $last_seen{lc $callsign};
	# 				print JS_DATA '<br>';
	# 			}
	# 			print JS_DATA "',\n";
	# 			print JS_DATA "    'graph':'http://kb8u.ham-radio-op.net/cricket/grapher.cgi?target=%2FTV%2F$callsign%2F" . lc $callsign . ";view=signal_info;ranges=d%3Aw%3Am%3Ay',\n";
	# 			print JS_DATA "    'strongest':0\n";
	# 			print JS_DATA "  },\n";
	# 		}
	# 		print JS_DATA "]\n";
	# 	}
	# 	close JS_DATA;
	# 	#  close SCAN_FILE;

		$conn->disconnect;
	}

	my $end_time = time();
	my $total_time = $end_time - $start_time;
	$wait_time = $wait - $total_time;
	$wait_time = ($wait_time <= 0 ? 10 : $wait_time);
} while($loop && (my $s = sleep $wait_time));

cleanup();

sub log_output
{
	my ($msg) = @_;
	print "$msg\n";
	if($log)
	{
		print LOG "$msg\n";
	}
}

sub rtrim
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

sub cleanup
{
	if($log)
	{
		close(LOG);
	}
	exit(0);
}