# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

TimeInterval.create(:interval => 2, :unit => 'day', :description => '2 days ago')
TimeInterval.create(:interval => 1, :unit => 'day', :description => '1 day ago')
TimeInterval.create(:interval => nil, :unit => nil, :description => 'All')
