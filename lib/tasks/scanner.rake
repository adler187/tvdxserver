#!/usr/bin/env ruby

require 'yaml'
require 'haversine'
require 'json'
require 'net/http'

# ============================
# from http://chrisroos.co.uk/blog/2006-10-20-boolean-method-in-ruby-sibling-of-array-float-integer-and-string
module Kernel
  def Boolean(string)
    return true if string == true || string =~ /^true$/i
    return false if string == false || string.nil? || string =~ /^false$/i
    raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
  end
end
# ============================

namespace :scanner do
  config = YAML.load_file("#{Rails.root}/config/scan.yml")
  if config.nil?
    $stderr.puts "Couldn't load config file"
    exit 1
  end

  env_config = config[Rails.env]
  if env_config.nil?
    $stderr.puts "No configuration for this environment specified"
    exit 1
  end

  tuners = env_config['tuners']
  if tuners.nil?
    $stderr.puts "No tuner configuration specified"
    exit 1
  end
  
  # if not set, set to true (default)
  env_config['log_results'] ||= true

  # set to false to prevent inserting in database useful for testing
  LOG_RESULTS = Boolean(env_config['log_results'])

  # if not set, set to 'scanner' (hope $PATH is set correctly)
  env_config['scan_program'] ||= 'scanner'

  CONFIG_PROG = env_config['scan_program']

  # location of tuner
  TUNER_LAT = env_config['latitude'].nil? ? nil : env_config['latitude'].to_f
  TUNER_LON = env_config['longitude'].nil? ? nil : env_config['longitude'].to_f
  LOCATION = !TUNER_LAT.nil? && !TUNER_LON.nil?

  # Distance to be considered a "DX"
  DX_DISTANCE = 100

  LOOP = Boolean(env_config['loop'])

  # if not set, set to 60 seconds (default)
  env_config['sleep_time'] ||= 60
  SLEEP_TIME = env_config['sleep_time']
  
  def log_output(log, message)
    if log.nil?
      puts message
    else
      log.puts message
    end
  end
  
  def scan(tuner_config)
    tuner_id = tuner_config['id']
    tuner_number = tuner_config['tuner']
    tuner = "/tuner#{tuner_config['tuner']}/"

    log = nil
    if LOG_RESULTS
  #     IO.sync = false
  #     log = File.new(tuner.gsub('/', '') + ".log", "w+")
    end
    
    tuner_obj = Tuner.first(:conditions => ['tuner_id = ? and tuner_number = ?', tuner_id, tuner_number])
    if tuner_obj.nil?
      $stderr.puts "No tuner in database yet!"
      exit
    end
    
    begin
      start_time = Time.now

      # log all output from scan, note when calls and all-time new calls are found
      scan_time = start_time.strftime('%Y-%m-%d %T')

      # scan tuner
      str = "#{CONFIG_PROG} -i #{tuner_id} -t #{tuner} 2> /dev/null"
      p str
      process = IO.popen(str, 'r')
  #     process = File.new('output.json', 'r')
      output = process.readlines.join
      process.close

      results = JSON.parse(output)

      results['scanresults'].each do |result|

        # set up some variables
        # TODO: add more variables here
        new_station = false
        distance = nil
        latitude = nil
        longitude = nil

        (broadcast_standard, channel) = result['channel'].split(':')
        if result['programcount'] > 0
          program = result['programs'][0]['number']
          virtual = result['programs'][0]['major']
          callsign_id = result['programs'][0]['idstring']

          puts "found station: #{callsign_id} with virtual channel #{virtual}. Using PSIP program number #{program}"

          station = Station.first(:conditions => ['tsid = ? and rf = ? and display = ?', result['tsid'], channel, virtual])

          if station.nil?
            new_station = true
            if result['tsid'] == '0x0001'
              log_output(log, "Received a station with an invalid tsid #{result['tsid']} on rf channel #{channel}, display channel #{virtual}, station IDs as #{callsign_id}, at #{scan_time}")
              log_output(log, "This is most likely a translator that has not been properly set up correctly")
              log_output(log, "You can add this station manually, but note that the tsid might change in the future when it gets set properly and will be re-added")
              log_output(log, "Signal: #{result['status']['ss']}, SNR: #{result['status']['snr']}, SER: #{result['status']['ser']}")
              next
            end

            callsign = callsign_id

            if(callsign.length > 4 && callsign.match(/\wDT$/))
              callsign = callsign[0, callsign.length-2]
            elsif callsign_match = callsign.match(/^((?:[CWKX][A-Z]{2,3})|(?:[KW]\d{1,2}[A-Z]{2}))/)
              callsign = callsign_match[1]
            else
              log_output(log, "getting callsign from rabbitears")
              host = 'www.rabbitears.info'
              page = '/oddsandends.php?request=tsid'

              req = Net::HTTP.new(host, nil)
              begin
                resp, data = req.get(page)
              rescue
                puts "Error loading #{host}#{page}"
                exit
                # TODO: log results for later
                next
              end

              if data_match = data.match(/<td>#{result['tsid']}&nbsp;<\/td><td><a href=(?:'|")\/market\.php\?request=station_search&callsign=\d+(?:'|")>((?:[CWKX][A-Z]{2,3})|(?:[KW]\d{1,2}[A-Z]{2}))(?:-(?:(?:TV)|(?:DT)))?<\/a>&nbsp;<\/td><td align='right'>(\d+)(?:&nbsp;)*<\/td><td align='right'>(\d+)/)
                callsign = data_match[1]
                realdisp = data_match[2]
                realrf = data_match[3]
                
                puts "#{realrf}, #{channel}, #{realdisp}, #{virtual},"

                unless(realrf == channel && realdisp.to_i == virtual.to_i)
                  log_output(log, "Found a translator of #{callsign}(#{result['tsid']}). IDs as #{callsign_id}, RF channel #{channel}, display channel #{virtual} at #{scan_time}, add manually")
                  log_output(log, "Signal: #{result['status']['ss']}, SNR: #{result['status']['snr']}, SER: #{result['status']['ser']}")
                  next
                end
              else
                log_output(log, "Couldn't find callsign for tsid #{result['tsid']} on channel #{channel}, display channel #{virtual}, station IDs as #{callsign_id}, at #{scan_time}, add manually")
                log_output(log, "Signal: #{result['status']['ss']}, SNR: #{result['status']['snr']}, SER: #{result['status']['ser']}")
                next
              end
            end
            
            log_output(log, "Found callsign #{callsign}")

            # facid: facility id number
            # call: callsign of station
            # chan: lower bound on channel number to search
            # cha2: upper bound on channel number to search
            # type: (3) Only licenced stations, no CPs or pending aps
            # list: (4) Text ouput, pipe delimited

            loading_data = true
            host = 'www.fcc.gov'
            page = "/fcc-bin/tvq?call=#{callsign}&chan=#{channel}&cha2=#{channel}&list=4"

            while(loading_data)
              req = Net::HTTP.new(host, nil)
              begin
                resp, data = req.get(page)
                if resp.response['Location']
                  uri = URI.parse(resp.response['Location'])
                  host = uri.host
                  page = "#{uri.path}?#{uri.query}"
                else
                  loading_data = false
                end
              rescue
                print "Error loading #{host}#{page}"
                exit
                # TODO: log results for later
                next
              end
            end

            lines = data.strip.split("\n")
            
            if lines.length == 0
              log_output(log, "Found a translator of callsign on channel #{channel} at #{scan_time}, add manually")
              log_output(log, "Signal: #{result['status']['ss']}, SNR: #{result['status']['snr']}, SER: #{result['status']['ser']}")
              next
            end

            lines.each do |line|
              tokens = line.split('|')
              tokens.each_index do |i|
                tokens[i] = tokens[i].strip
              end

              unused,
              call,
              unused,
              lic_type,
              chan,
              app_type,
              unused,
              tv_zone,
              unused,
              antenna_type,
              city,
              state,
              country,
              fileno,
              erp,
              unused,
              haat,
              unused,
              facid,
              lat,
              lat_deg,
              lat_min,
              lat_sec,
              long,
              long_deg,
              long_min,
              long_sec,
              licencee,
              km,
              mi,
              azimuth,
              amsl,
              polarization,
              antenna_id,
              rotation,
              asrn,
              agl = tokens

              if lic_type.match(/STA/)
                next
              end
              
              latitude = (lat_deg.to_f + lat_min.to_f/60 + lat_sec.to_f/3600) * (lat == 'S' ? -1 : 1)
              longitude = (long_deg.to_f + long_min.to_f/60 + long_sec.to_f/3600) * (long == 'W' ? -1 : 1)

              if LOCATION
                puts 'calculating distance'
                distance = haversine_distance(TUNER_LAT, TUNER_LON, latitude, longitude)['mi']
              end

              if lic_type.match(/LIC/)
                break
              end

            end

            puts "#{callsign}: #{latitude}, #{longitude}, #{distance}"

            if LOG_RESULTS
              station = Station.create(
                :tsid => result['tsid'],
                :callsign => callsign,
                :parent_callsign => nil,
                :rf => channel.to_i,
                :display => virtual.to_i,
                :latitude => latitude,
                :longitude => longitude,
                :distance => distance
              )

              p station
              
              if !station.save
                station.errors
              end
            end
          end

          if (true || distance > DX_DISTANCE || new_station)
            status = result['status']
            result_log = Log.create(
              :signal_strength => status['ss'],
              :signal_to_noise => status['snr'],
              :signal_quality => status['ser'],
              :station => station,
              :tuner => tuner_obj
            )
            if !result_log.save
              result_log.errors
            end
          end
        end
      end

      end_time = Time.now
      total_time = end_time - start_time
      wait_time = SLEEP_TIME - total_time
      wait_time = wait_time <= 0 ? 10 : wait_time
    end while LOOP && (sleep wait_time)

    if log
      log.close
    end
  end

  desc "Scan HDHomeRun tuners"
  task :scan => :environment do
    puts "Scanning ..."
    p tuners
    threads = []
    tuners.each do |name, tuner|
      p tuner
      threads << Thread.new(tuner) do |myTuner|
        scan(myTuner)
      end
    end

    threads.each do |thread|
      thread.join
    end
  end
end
