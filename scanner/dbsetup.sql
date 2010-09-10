CREATE TABLE IF NOT EXISTS stations (
	id int unsigned NOT NULL AUTO_INCREMENT,
	tsid varchar(6) NOT NULL,
	callsign varchar(10) NOT NULL,
	parentcall varchar(7) NOT NULL,
	rf tinyint NOT NULL,
	display tinyint NOT NULL,
	latitude decimal(6,4) NOT NULL,
	longitude decimal(6,4) NOT NULL,
	distance decimal(5,1) DEFAULT NULL,
	PRIMARY KEY (id)
) ENGINE=MyISAM;

CREATE TABLE IF NOT EXISTS tuners (
	id int unsigned NOT NULL,
	tunerid varchar(15) NOT NULL,
	aim varchar(20) NOT NULL,
	antenna varchar(100) NOT NULL,
	latitude decimal(6,4) DEFAULT NULL,
	longitude decimal(6,4) DEFAULT NULL,
	PRIMARY KEY (id)
) ENGINE=MyISAM;

CREATE TABLE IF NOT EXISTS log (
	id int unsigned NOT NULL DEFAULT 0,
	tunerid int unsigned NOT NULL,
	ss tinyint NOT NULL,
	snq tinyint NOT NULL,
	seq tinyint NOT NULL,
	logtime datetime NOT NULL,
	PRIMARY KEY (id,tunerid,logtime)
) ENGINE=MyISAM;


DROP TABLE IF EXISTS time_intervals;
CREATE TABLE time_intervals (
	time_interval varchar(3) NOT NULL,
	description varchar(20) NOT NULL,
	PRIMARY KEY(time_interval)
) ENGINE=MyISAM;

INSERT INTO time_intervals VALUES('48', 'Last 48 hours');
INSERT INTO time_intervals VALUES('12', 'Last 12 Hours');
INSERT INTO time_intervals VALUES('6', 'Last 6 Hours');
INSERT INTO time_intervals VALUES('1', 'Last hour');
INSERT INTO time_intervals VALUES('ALL', 'All results');

DELIMITER !
DROP PROCEDURE IF EXISTS GetLogInfo!
CREATE PROCEDURE GetLogInfo(IN tunerid int, IN mindistance int, IN time_interval int)
BEGIN
SELECT
	stations.id,
	stations.callsign,
	stations.parentcall,
	stations.latitude,
	stations.longitude,
	stations.distance,
	stations.rf,
	log.ss,
	log.snq,
	log.seq,
	MAX(log.logtime) as logtime
FROM stations, log
WHERE
	stations.id = log.id AND
	log.tunerid = tunerid AND
	logtime > DATE_ADD(DATE_SUB(NOW(), interval time_interval HOUR), interval 2 HOUR) AND
	distance > mindistance
GROUP BY(stations.callsign);
END!

DROP PROCEDURE IF EXISTS GetAllLogInfo!
CREATE PROCEDURE GetAllLogInfo(IN tunerid int, IN mindistance int)
BEGIN
SELECT
	stations.id,
	stations.callsign,
	stations.parentcall,
	stations.latitude,
	stations.longitude,
	stations.distance,
	stations.rf,
	log.ss,
	log.snq,
	log.seq,
	MAX(log.logtime) as logtime
FROM stations, log
WHERE
	stations.id = log.id AND
	log.tunerid = tunerid AND
	distance > mindistance
GROUP BY(stations.callsign);
END!

DELIMITER ;