#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'haversine'
require 'ffi-hdhomerun'
require 'open-uri'

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
    log = nil
    if LOG_RESULTS
  #     IO.sync = false
  #     log = File.new(tuner.gsub('/', '') + ".log", "w+")
    end
        
    tuner_obj = Tuner.first(:conditions => ['tuner_id = ? and tuner_number = ?', tuner_config['id'], tuner_config['tuner']])
    if tuner_obj.nil?
      $stderr.puts "No tuner in database yet!"
      exit
    end
    
    begin
      start_time = Time.now

      # log all output from scan, note when calls and all-time new calls are found
      scan_time = start_time.strftime('%Y-%m-%d %T')
      
      # scan tuner
      tuner = HDHomeRun::Tuner.new(:id => tuner_config['id'], :tuner => tuner_config['tuner'])
      
      tuner.scan do |result|
        # set up some variables
        # TODO: add more variables here
        new_station = false
        distance = nil
        latitude = nil
        longitude = nil

        if result.program_count > 0
          program = result.programs[0]
          
          puts "found station: #{program.name} with virtual channel #{program.major}. Using PSIP program number #{program.number}"

          station = Station.first(:conditions => ['tsid = ? and rf = ? and display = ?', result.tsid, result.channel, program.major])

          if station.nil?
            new_station = true
            if result.tsid == '0x0001'
              log_output(log, "Received a station with an invalid tsid #{result.tsid} on rf channel #{result.channel}, display channel #{program.major}, station IDs as #{program.name}, at #{scan_time}")
              log_output(log, "This is most likely a translator that has not been properly set up correctly")
              log_output(log, "You can add this station manually, but note that the tsid might change in the future when it gets set properly and will be re-added")
              log_output(log, "Signal: #{result.status.signal_strength}, SNR: #{result.status.signal_to_noise}, SER: #{result.status.symbol_error_rate}")
              next
            end

            callsign = program.name

            if(callsign.length > 4 && callsign.match(/\wDT$/))
              callsign = callsign[0, callsign.length-2]
            elsif callsign_match = callsign.match(/^((?:[CWKX][A-Z]{2,3})|(?:[KW]\d{1,2}[A-Z]{2}))/)
              callsign = callsign_match[1]
            else
              log_output(log, "getting callsign from rabbitears for tsid #{result.tsid}")
              
              data = open(URI.parse 'http://www.rabbitears.info/oddsandends.php?request=tsid')
              
              # TODO: log results for later
              next if data.nil?

              if data_match = data.read.match(/<td>#{result.tsid}&nbsp;<\/td><td><a href=(?:'|")\/market\.php\?request=station_search&callsign=\d+(?:'|")>((?:[CWKX][A-Z]{2,3})|(?:[KW]\d{1,2}[A-Z]{2}))(?:-(?:(?:TV)|(?:DT)))?<\/a>&nbsp;<\/td><td align='right'>(\d+)(?:&nbsp;)*<\/td><td align='right'>(\d+)/)
                callsign = data_match[1]
                realdisp = data_match[2]
                realrf = data_match[3]
                
                puts "#{realrf}, #{result.channel}, #{realdisp}, #{program.major},"

                unless(realrf == result.channel && realdisp.to_i == program.major.to_i)
                  log_output(log, "Found a translator of #{callsign}(#{result.tsid}). IDs as #{program.name}, RF channel #{result.channel}, display channel #{program.major} at #{scan_time}, add manually")
                  log_output(log, "Signal: #{result.status.signal_strength}, SNR: #{result.status.signal_to_noise}, SER: #{result.status.symbol_error_rate}")
                  next
                end
              else
                log_output(log, "Couldn't find callsign for tsid #{result.tsid} on channel #{result.channel}, display channel #{program.major}, station IDs as #{program.name}, at #{scan_time}, add manually")
                log_output(log, "Signal: #{result.status.signal_strength}, SNR: #{result.status.signal_to_noise}, SER: #{result.status.symbol_error_rate}")
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
            data = open(URI.parse "http://www.fcc.gov/fcc-bin/tvq?call=#{callsign}&chan=#{result.channel}&cha2=#{result.channel}&list=4")
            
            # TODO: log results for later
            next if data.nil?
            
            lines = data.read.strip.split("\n")
            
            if lines.length == 0
              log_output(log, "Found a translator of callsign on channel #{result.channel} at #{scan_time}, add manually")
              log_output(log, "Signal: #{result.status.signal_strength}, SNR: #{result.status.signal_to_noise}, SER: #{result.status.symbol_error_rate}")
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
                :tsid => result.tsid,
                :callsign => callsign,
                :parent_callsign => nil,
                :rf => result.channel.to_i,
                :display => program.major.to_i,
                :latitude => latitude,
                :longitude => longitude,
                :distance => distance
              )

              if !station.save
                station.errors
              end
            end
          end

          if (true || distance > DX_DISTANCE || new_station)
            result_log = Log.create(
              :signal_strength => result.status.signal_strength,
              :signal_to_noise => result.status.signal_to_noise,
              :signal_quality => result.status.symbol_error_rate,
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
