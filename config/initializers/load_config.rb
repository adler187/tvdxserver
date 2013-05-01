# require 'yaml'
# 
# CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'config.yml'))[Rails.env]

CONFIG = Hash.new
%w(name latitude longitude perform_authentication username password).each do |envvar|
  p envvar
  CONFIG[envvar] = ENV[envvar]
end
