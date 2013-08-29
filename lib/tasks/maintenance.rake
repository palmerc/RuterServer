require 'csv'
require 'uri'
require 'net/http'
require 'iconv'
require 'geoutm/lib/geoutm'

namespace :maintenance do
  desc "Download the stops CSV and update the database"
  task :update_stops => :environment do
    ruterStopsURI = URI.parse(URI.encode('http://sqlweb1.trafikanten.no:8080/tabledump/stops2.csv'))
    columnSeparator = ';'
    stopIDKey = 'StopID'
    nameKey = 'Name'
    shortnameKey = 'Shortname'
    municipalityKey = 'Municipality'
    fareZoneKey = 'Zone'
    eastingKey = 'X'
    northingKey = 'Y'
    optionalKey = 'Optional'

    headers = [stopIDKey, nameKey, shortnameKey, municipalityKey, fareZoneKey, eastingKey, northingKey, optionalKey].join(columnSeparator)
    count = 0

    outFilePath = Dir.tmpdir + '/' + 'stops.csv'
    puts outFilePath
    Net::HTTP.start(ruterStopsURI.host, ruterStopsURI.port) do |http|
      begin
        outFile = File.open(outFilePath, 'wb')
        response = Net::HTTP.get_response(ruterStopsURI)
        body = response.read_body
        outFile.write(body)
      ensure
        outFile.close
      end
    end

    inFile = File.open(outFilePath, 'r:bom|UTF-16LE')
    begin
      while (line = inFile.readline) do
        CSV.parse(line, :col_sep => columnSeparator, :headers => headers) do |row|
          row = row.to_hash.with_indifferent_access

          stop_id = row[stopIDKey]
          name = row[nameKey]
          shortname = row[shortnameKey]
          municipality = row[municipalityKey]
          fareZone = row[fareZoneKey]

          easting = row[eastingKey]
          northing = row[northingKey]

          optional = row[optionalKey]

          begin
            utm = GeoUtm::UTM.new('32V', easting.to_f, northing.to_f)
            coordinates = utm.to_lat_lon
            latitude = coordinates.lat
            longitude = coordinates.lon
          rescue GeoUtm::GeoUtmException => e
            puts "#{count} - #{stop_id}, #{name}, #{easting}, #{northing}"
          end
          Stop.create!(:latitude => latitude,
                       :longitude => longitude,
                       :northing => northing,
                       :easting => easting,
                       :name => name,
                       :stop_id => stop_id)
          count += 1
        end
      end
    rescue EOFError => e
    end

    if File.exists?(outFilePath)
      File.delete(outFilePath)
    end
  end
end

