#############################
### Build a new world.db

require 'pp'
require 'worlddb'


BUILD_DIR = "."
DATA_DIR  = "./db"


WORLD_DB_PATH = "#{BUILD_DIR}/world.db"

DB_CONFIG = {
  adapter:  'sqlite3',
  database:  WORLD_DB_PATH
}




task :default => 'release'


desc "clean db build for release"
task :release => [:clean,:create,:import] do
  puts "hello from world.db release build script"
end

task :clean do
  rm WORLD_DB_PATH if File.exists?( WORLD_DB_PATH )
end

task :env do
  pp DB_CONFIG
  ActiveRecord::Base.establish_connection( DB_CONFIG )
end

desc "create db schema"
task :create => [:env, :clean] do
  WorldDB.create
end

desc "import db seeds from folder '#{DATA_DIR}'"
task :import => :env do

  reader = WorldDB::Reader.new
  
  excludes = [
      'america/br/cities'
  ]
  names = WorldDB.fixtures - excludes
  
  names.each do |name|
    reader.load_with_include_path( name, DATA_DIR )
  end

  WorldDB.stats

end



=begin
task :world => [:countries,:regions,cities] do
  
end

task :countries => :env do

  reader = WorldDB::Reader.new
 
#  FileList['*/countries.txt'].each do |file|
  ## todo: remove .txt extension
#  end
  
end

task :regions
task :cities
=end