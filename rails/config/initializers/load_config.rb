require 'yaml'

SCAN_CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'scan.yml'))[RAILS_ENV]
