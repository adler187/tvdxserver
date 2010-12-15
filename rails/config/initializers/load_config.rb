require 'yaml'

CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'config.yml'))[RAILS_ENV]
