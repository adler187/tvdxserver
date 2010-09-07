/*
 * hdhomerun_scan.c
 *
 * Copyright © 2010 Kevin Adler
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <getopt.h>
#include "hdhomerun.h"

char *appname;

struct hdhomerun_device_t *hd;

int help(void)
{
	printf("Usage:\n");
	printf("\t%s [-h] -i <tuner id> -t <tuner>\n", appname);
	return 0;
}

bool_t sigabort = FALSE;

void signal_abort(int arg)
{
	sigabort = TRUE;
}

int scan(const char *tuner)
{
	if (hdhomerun_device_set_tuner_from_str(hd, tuner) <= 0)
	{
		fprintf(stderr, "invalid tuner number\n");
		return -1;
	}

	char *ret_error;
	if (hdhomerun_device_tuner_lockkey_request(hd, &ret_error) <= 0)
	{
		fprintf(stderr, "failed to lock tuner\n");
		if (ret_error)
		{
			fprintf(stderr, "%s\n", ret_error);
		}
		return -1;
	}

	hdhomerun_device_set_tuner_target(hd, "none");

	char *channelmap;
	if (hdhomerun_device_get_tuner_channelmap(hd, &channelmap) <= 0)
	{
		fprintf(stderr, "failed to query channelmap from device\n");
		return -1;
	}

	const char *channelmap_scan_group = hdhomerun_channelmap_get_channelmap_scan_group(channelmap);
	if (!channelmap_scan_group)
	{
		fprintf(stderr, "unknown channelmap '%s'\n", channelmap);
		return -1;
	}

	if (hdhomerun_device_channelscan_init(hd, channelmap_scan_group) <= 0)
	{
		fprintf(stderr, "failed to initialize channel scan\n");
		return -1;
	}

	signal(SIGINT, signal_abort);
	signal(SIGPIPE, signal_abort);

	int ret = 0;
	
	printf("{\n\tscanresults:\n\t[\n");
	while (!sigabort)
	{
		struct hdhomerun_channelscan_result_t result;
		ret = hdhomerun_device_channelscan_advance(hd, &result);
		if (ret < 1)
		{
			break;
		}

		ret = hdhomerun_device_channelscan_detect(hd, &result);
		if (ret < 1)
		{
			break;
		}
		
		bool_t showall = TRUE;
		
		printf("\t\t{\n");
		
		if (showall || result.transport_stream_id_detected)
		{
			printf("\t\t\t'channel': '%s',\n", result.channel_str);
			printf("\t\t\t'channelmap': '%i',\n", result.channelmap);
			printf("\t\t\t'frequency': %lu,\n", result.frequency);
			printf("\t\t\t'programcount': %i,\n", result.program_count);
			
			printf("\t\t\t'status':\n");
			printf("\t\t\t{\n");
			printf("\t\t\t\t'channel': '%.32s',\n", result.status.channel);
			printf("\t\t\t\t'modulation': '%s',\n", result.status.lock_str);
			printf("\t\t\t\t'signal': %s,\n", result.status.signal_present ? "true" : "false");
			printf("\t\t\t\t'supported': %s,\n", result.status.lock_supported ? "true" : "false");
			printf("\t\t\t\t'ss': %u,\n", result.status.signal_strength);
			printf("\t\t\t\t'snr': %u,\n", result.status.signal_to_noise_quality);
			printf("\t\t\t\t'ser': %u,\n", result.status.symbol_error_quality);
			printf("\t\t\t\t'bps': %u,\n", result.status.raw_bits_per_second);
			printf("\t\t\t\t'pps': %u,\n", result.status.packets_per_second);
			printf("\t\t\t}\n");
			
			if(result.transport_stream_id_detected)
			{
				printf("\t\t\t'tsid': '0x%04X',\n", result.transport_stream_id);
				
				printf("\t\t\t'programs':\n\t\t\t[\n");
				for (int i = 0; i < result.program_count; i++)
				{
					struct hdhomerun_channelscan_program_t *program = &result.programs[i];
					
					printf("\t\t\t\t{\n");
					printf("\t\t\t\t\t'program': %.64s,\n", program->program_str);
					printf("\t\t\t\t\t'number': %i,\n", program->program_number);
					printf("\t\t\t\t\t'major': %i,\n", program->virtual_major);
					printf("\t\t\t\t\t'minor': %i,\n", program->virtual_minor);
					printf("\t\t\t\t\t'type': %i,\n", program->type);
					printf("\t\t\t\t\t'idstring': '%.32s'\n", program->name);
					printf("\t\t\t\t},\n");
				}
				printf("\t\t\t]\n");
			}
		}
		
		printf("\t\t},\n");
	}
	
	printf("\t]\n}\n");
	
	hdhomerun_device_tuner_lockkey_release(hd);
	
	if (ret < 0)
	{
		fprintf(stderr, "communication error sending request to hdhomerun device\n");
	}
	return ret;
}

int main(int argc, char *argv[])
{
	char *tunerid = NULL, *tuner = NULL;
	int c;
	
	// Get the appname
	appname = basename(argv[0]);
	
	while((c = getopt(argc, argv, "hi:t:")) != -1)
	{
		switch(c)
		{
			case 'h':
				return help();
				break;
				
			case 'i':
				tunerid = optarg;
				break;
				
			case 't':
				tuner = optarg;
				break;
				
			case '?':
				switch(optopt)
				{
					case 'i':
						fprintf(stderr, "Option -%c requires an argument\n", optopt);
						return help();
						break;
						
					default:
						fprintf(stderr, "Unknown option\n");
				}
				break;
		}
	}
	
	if(tuner == NULL || tunerid == NULL)
	{
		return help();
	}

	/* Device object. */
	hd = hdhomerun_device_create_from_str(tunerid, NULL);
	if (!hd)
	{
		fprintf(stderr, "invalid device id: %s\n", tunerid);
		return -1;
	}

	/* Device ID check. */
	uint32_t device_id_requested = hdhomerun_device_get_device_id_requested(hd);
	if (!hdhomerun_discover_validate_device_id(device_id_requested))
	{
		fprintf(stderr, "invalid device id: %08lX\n", (unsigned long)device_id_requested);
	}

	/* Connect to device and check model. */
	const char *model = hdhomerun_device_get_model_str(hd);
	if (!model)
	{
		fprintf(stderr, "unable to connect to device\n");
		hdhomerun_device_destroy(hd);
		return -1;
	}
	
	scan(tuner);

	/* Cleanup. */
	hdhomerun_device_destroy(hd);

	/* Complete. */
	return 0;
}
