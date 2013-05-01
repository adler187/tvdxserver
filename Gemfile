source 'http://rubygems.org'

gem 'rails', '~> 3.2.0'

group :development, :test do
  gem 'capistrano'
	gem 'sqlite3'
end

# Assume deploying to Heroku if the 
# DATABASE_URL environment variable is set
HEROKU = !ENV['DATABASE_URL'].nil?
p ENV

if HEROKU
  group :production do
    gem 'pg'
  end
else
  group :production do
    gem 'mysql2'
  end
end

group :scan do
  gem 'ffi-hdhomerun'
  gem 'rest-client'
end

# group :assets do
#   gem 'sass-rails', '~> 3.2.3'
#   gem 'coffee-rails', '~> 3.2.1'
#   gem 'uglifier', '>= 1.0.3'
# end

gem 'acts_as_list'
gem 'jquery-rails'
gem 'figaro'
