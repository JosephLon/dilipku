## for use to run with interactive ruby (irb)
##  e.g.  irb -r worlddb/console

require 'worlddb'

# some ruby stdlibs

require 'logger'
require 'pp'   # pretty printer
require 'uri'
require 'json'
require 'yaml'


## shortcuts for models

Tag     = WorldDB::Models::Tag
Tagging = WorldDB::Models::Tagging
Country = WorldDB::Models::Country
Region  = WorldDB::Models::Region
City    = WorldDB::Models::City
Prop    = WorldDB::Models::Prop

## connect to db

DB_CONFIG = {
  adapter:  'sqlite3',
  database: 'world.db'
}

pp DB_CONFIG
ActiveRecord::Base.establish_connection( DB_CONFIG )



## test drive

puts "Welcome to world.db, version #{WorldDB::VERSION}!"
puts "  #{'%6d' % Country.count} countries"
puts "  #{'%6d' % Region.count} regions"
puts "  #{'%6d' % City.count} cities"
puts "  #{'%6d' % Tagging.count} taggings"
puts "  #{'%6d' % Tag.count} tags"
puts "Ready."

## some countries

## add some predefined shortcuts

##### some countries

at = Country.find_by_key( 'at' )
de = Country.find_by_key( 'de' )
en = Country.find_by_key( 'en' )

us = Country.find_by_key( 'us' )
ca = Country.find_by_key( 'ca' )
mx = Country.find_by_key( 'mx' )

### some cities

nyc = City.find_by_key( 'newyork' )
lon = City.find_by_key( 'london' )
vie = City.find_by_key( 'wien' )

## todo: add some predefined tags (e.g. europe, america, g8, euro, etc.)


## turn on activerecord logging to console

ActiveRecord::Base.logger = Logger.new( STDOUT )
