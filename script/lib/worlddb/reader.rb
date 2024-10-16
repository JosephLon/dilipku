module WorldDB

class Reader

## make models available in sportdb module by default with namespace
#  e.g. lets you use City instead of Models::City
  include WorldDB::Models


  def initialize( logger=nil )
    if logger.nil?
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
    else
      @logger = logger
    end
  end

  attr_reader :logger

  def run( opts, args )
 
    args.each do |arg|
      name = arg     # File.basename( arg, '.*' )

      if opts.load?
        load_countries_builtin( name )             if opts.countries?
        load_regions_builtin( opts.country, name ) if opts.regions?
        load_cities_builtin( opts.country, name )  if opts.cities?
      else
        load_countries_with_include_path( name, opts.data_path )              if opts.countries?
        load_regions_with_include_path( opts.country, name, opts.data_path )  if opts.regions?
        load_cities_with_include_path( opts.country, name, opts.data_path )   if opts.cities?
      end
    end

  end


  ############################
  # load from file system
  
  def load_with_include_path( name, include_path )
    if name =~ /\/countries/
      load_countries_with_include_path( name, include_path )
    elsif name =~ /\/([a-z]{2})\/cities/
      load_cities_with_include_path( $1, name, include_path )
    elsif name =~ /\/([a-z]{2})\/regions/
      load_regions_with_include_path( $1, name, include_path )
    else
      puts "*** error: unknown world.db fixture type >#{name}<"
      # todo/fix: exit w/ error
    end
  end

  def load_countries_with_include_path( name, include_path )
    load_fixtures_with_include_path_for( Country, name, include_path )
  end

  def load_regions_with_include_path( country_key, name, include_path )
    country = Country.find_by_key!( country_key )
    puts "Country #{country.key} >#{country.title} (#{country.code})<"

    load_fixtures_with_include_path_for( Region, name, include_path, country_id: country.id )
  end

  def load_cities_with_include_path( country_key, name, include_path )  
    country = Country.find_by_key!( country_key )
    puts "Country #{country.key} >#{country.title} (#{country.code})<"

    load_fixtures_with_include_path_for( City, name, include_path, country_id: country.id )
  end
  
  ##################################
  #  load from gem (built-in)

  def load_builtin( name )  ## convenience helper (requires proper named files w/ convention)
    if name =~ /\/countries/
       load_countries_builtin( name )
    elsif name =~ /\/([a-z]{2})\/cities/
       load_cities_builtin( $1, name )
    elsif name =~ /\/([a-z]{2})\/regions/
       load_regions_builtin( $1, name )
    else
       puts "*** error: unknown world.db fixture type >#{name}<"
       # todo/fix: exit w/ error
    end
  end

  def load_countries_builtin( name ) 
    load_fixtures_builtin_for( Country, name )
  end

  def load_regions_builtin( country_key, name )
    country = Country.find_by_key!( country_key )
    puts "Country #{country.key} >#{country.title} (#{country.code})<"
  
    load_fixtures_builtin_for( Region, name, country_id: country.id )
  end
  
  def load_cities_builtin( country_key, name )
    country = Country.find_by_key!( country_key )
    puts "Country #{country.key} >#{country.title} (#{country.code})<"

    load_fixtures_builtin_for( City, name, country_id: country.id )
  end


private
  def load_fixtures_with_include_path_for( clazz, name, include_path, more_values={} )  # load from file system
    path = "#{include_path}/#{name}.txt"

    puts "*** parsing data '#{name}' (#{path})..."

    reader = ValuesReader.new( logger, path, more_values )
    
    load_fixtures_worker_for( clazz, reader )

    Prop.create!( key: "db.#{fixture_name_to_prop_key(name)}.version", value: "file.txt.#{File.mtime(path).strftime('%Y.%m.%d')}" )        
  end

  def load_fixtures_builtin_for( clazz, name, more_values={} ) # load from gem (built-in)
    path = "#{WorldDB.root}/db/#{name}.txt"

    puts "*** parsing data '#{name}' (#{path})..."

    reader = ValuesReader.new( logger, path, more_values )
    
    load_fixtures_worker_for( clazz, reader )

    Prop.create!( key: "db.#{fixture_name_to_prop_key(name)}.version", value: "world.txt.#{WorldDB::VERSION}" )
  end


  def load_fixtures_worker_for( clazz, reader )
   
    ## NB: assumes active activerecord db connection
    ##

    reader.each_line do |attribs, values|
  
      value_numbers = []
      
      ## check for optional values
      values.each_with_index do |value,index|
        if value =~ /^region:/   ## region:
          value_region_key = value[7..-1]  ## cut off region: prefix
          value_region = Region.find_by_key!( value_region_key )
          attribs[ :region_id ] = value_region.id
        elsif value =~ /^[A-Z]{3}$/  ## assume three-letter code
          attribs[ :code ] = value
        elsif value =~ /^\d+$/    ## numeric
          value_numbers << value.to_i
        elsif (values.size==(index+3)) && value =~ /^[a-z0-9\| ]+$/   # tags must be last entry
          puts "   skipping tags: #{value}"
        else
          # issue warning: unknown type for value
          puts "*** warning: unknown type for value >#{value}<"
        end
      end
      
      if value_numbers.size > 0
        if clazz == City
          attribs[ :pop  ] = value_numbers[0]   # assume first number is pop for cities
          attribs[ :area ] = value_numbers[1]  
        else   # countries,regions
          attribs[ :area ] = value_numbers[1]
          attribs[ :pop  ] = value_numbers[0]
        end
      end

      rec = clazz.find_by_key( attribs[ :key ] )
      if rec.present?
        ## nb: [17..-1] cut off WorldDB::Models:: in name
        puts "*** update #{clazz.name[17..-1].downcase} #{rec.id}-#{rec.key}:"
      else
        puts "*** create #{clazz.name[17..-1].downcase}:"
        rec = clazz.new
      end
      
      puts attribs.to_json
   
      rec.update_attributes!( attribs )
        
    end # each_line
            
  end # method load_fixture_worker_for

  
end # class Reader
end # module WorldDB
