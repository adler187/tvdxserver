#!/usr/bin/env perl

# scan tuner on Silicon Dust HDHomeRun to collect TV station channel, callsign
# and strength.  Locate station using FCC web site.  Write to log file

use List::MoreUtils qw(any none);
use Date::Format;
use Config::IniFiles;
use LWP::Simple;
use Math::Trig qw(great_circle_distance deg2rad);
use Data::Dumper;

use DBI;

use constant false => 0;
use constant true  => 1;

use threads;

my %ini;
tie %ini, 'Config::IniFiles', ( -file => 'config.ini' );

# program used to interface with tuner
my $CONFIG_PROG = $ini{'cfg'}{'prog'};

my @tuner_list = split(/\s+/, $ini{'cfg'}{'tuners'});

my @tuners = ();
foreach my $tuner (@tuner_list)
{
	@device_list = split(/\s+/, $ini{$tuner}{'tuners'});
	@db_id_list = split(/\s+/, $ini{$tuner}{'dbtunerids'});

	for($i=0; $i<scalar(@device_list); $i++)
	{
		push @tuners, {'tunerid' => $ini{$tuner}{'tunerid'}, 'tuner' => $device_list[$i], 'dbtunerid' => $db_id_list[$i], 'frequencies' => $ini{$tuner}{'frequencies'}};
	}
}

# location of tuner
my $TUNER_LAT = $ini{'info'}{'latitude'};
my $TUNER_LON = $ini{'info'}{'longitude'};

# Distance to be considered a "DX"
my $DX_DISTANCE = 100;

my $database = $ini{'db'}{'database'};
my $hostname = $ini{'db'}{'host'};
my $port = $ini{'db'}{'port'};
my $user = $ini{'db'}{'username'};
my $password = $ini{'db'}{'pass'};

my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";

my $drh = DBI->install_driver("mysql");

my $loop = ($ini{'cfg'}{'loop'} eq "true" ? 1 : '');

my $wait = $ini{'cfg'}{'wait'};

my $wait = ($wait ? $wait : 60);
my $wait_time = 0;

if(defined($ini{'cfg'}{'latitude'}) && defined($ini{'cfg'}{'longitude'}))
{
	my $latitude = $ini{'cfg'}{'latitude'};
	my $longitude = $ini{'cfg'}{'longitude'};

	@mylocation = ( deg2rad($longitude), deg2rad(90 - $latitude) );
}

# If more than one tuner, use multiple threads
if(scalar(@tuners) > 1)
{
	for($i = 0; $i < scalar(@tuners); $i++)
	{
		threads->create('scan', $tuners[$i]);
	}
	
	foreach my $thr (threads->list())
	{
        $thr->join();
	}
}
# otherwise don't use any threads
else
{
	scan($tuners[0]);
}

sub scan
{
	my ($info) = @_;
	my %infohash = %{$info};

	my $tunerid = $infohash{'tunerid'};
	my $dbtunerid = $infohash{'dbtunerid'};
	my $tuner = $infohash{'tuner'};

	my $log = true;
	open LOG, ">>tuner-$tunerid-".substr($tuner, -2, 1).".log" or $log = false;
	
	my $prev_default = select(LOG);
	
	# remove buffering for LOG
	$| = 1;
	
	select($prev_default);
	
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
			open SCAN, "$CONFIG_PROG $tunerid scan $tuner |" or die "can't run scan";

			my ($id, $tsid, $freq, $channel, $modulation, $strength, $sig_noise, $symbol_err, $program, $number, $callsign, $latitude, $longitude, $distance, $new, $callsign_id);
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
					$callsign_id = '';
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
					$callsign_id = $3;
				}

				if ($program)
				{

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
						if($tsid eq '0x0001')
						{
							log_output("Received a station with an invalid tsid $tsid on rf channel $channel, display channel $number, station IDs as $callsign_id, at $file_time");
							log_output("This is most likely a translator that has not been properly set up correctly");
							log_output("You can add this station manually, but note that the tsid might change in the future when it gets set properly and will be re-added");
							log_output("Signal: $strength, SNR: $sig_noise, SER: $symbol_err");
							next;
						}

						$callsign = $callsign_id;
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
									log_output("Found a translator of $callsign($tsid). IDs as $callsign_id, RF channel $channel, display channel $number at $file_time, add manually");
									log_output("Signal: $strength, SNR: $sig_noise, SER: $symbol_err");
									last;
								}
							}
							else
							{
								log_output("Couldn't find callsign for tsid $tsid on channel $channel, display channel $number, station IDs as $callsign_id, at $file_time, add manually");
								log_output("Signal: $strength, SNR: $sig_noise, SER: $symbol_err");
								last;
							}
							log_output("Found callsign $callsign");
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
							) = @tokens;

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
							$rs = $conn->prepare("insert into log values($id, $dbtunerid, $strength, $sig_noise, $symbol_err, '$file_time')");
							$rs->execute();
							$rs->finish();
						}
					}
				}
			}
			$conn->disconnect;
		}

		my $end_time = time();
		my $total_time = $end_time - $start_time;
		$wait_time = $wait - $total_time;
		$wait_time = ($wait_time <= 0 ? 10 : $wait_time);
	} while($loop && (my $s = sleep $wait_time));
	
	if($log)
	{
		close(LOG);
	}
	
	sub log_output
	{
		my ($msg) = @_;
		print "$msg\n";
		if($log)
		{
			print LOG "$msg\n";
		}
	}
}

sub rtrim
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}
