# require 'yaml'
# 
# CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'config.yml'))[Rails.env]

CONFIG = Hash.new
DEFAULTS = {
  perform_authentication: false,
  fromemail: 'webmaster'
}

%w(name latitude longitude perform_authentication username password email fromemail).each do |envvar|
  CONFIG[envvar] = ENV[envvar]
  CONFIG[envvar] ||= DEFAULTS[envvar.to_sym]
end

# check required attributes
%w(name latitude longitude).each do |envvar|
  if CONFIG[envvar].nil?
    Rails.logger.fatal "#{envvar} config variable not set in application.yml, terminating"
    exit 1
  end
end

if CONFIG['perform_authentication']
  %w(username password).each do |envvar|
    if CONFIG[envvar].nil?
      Rails.logger.warn "#{envvar} config variable not set in application.yml, but authentication requested - access will be disabled"
      break
    end
  end
end
