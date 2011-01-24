#!/usr/bin/ruby

# Copyright 2007, 2008 Richard Gould, rwgould@gmail.com
#
# This file is part of YAAFT.
#
# YAAFT is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# YAAFT is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with YAAFT.  If not, see <http://www.gnu.org/licenses/>.
#

require 'net/http'
require 'cgi'
require 'date'

class ScrobbleCache

  class Server500Error < RuntimeError
  end

  # Creates a ScrobbleCache that will cache responses from the server, and
  # make sure that requests are not made too frequently (as this could result
  # in your IP being banned from the audioscrobbler web services).
  #
  # +baseLocation+ is a path to where the cache will be stored. It must be
  # a directory and you must be able to read and write from it.
  #
  # +staleTolerance+ is the number of days before data in the cache is
  # considered stale. Stale data in the cache is ignored when reading
  # the cache.
  #
  # +timeBetweenRequests+ is the minimum number of seconds between requests
  # to the audioscrobbler web services.
  #
  # +maxRetries+ is the number of retries to make when the server throws
  # an error
  #
  # +timeBetweenRetries+ is the number of seconds to wait between retries
  def initialize (baseLocation = "~/.yaaft/scrobbleCache", staleTolerance = 14, timeBetweenRequests = 1, maxRetries = 30, timeBetweenRetries = 5)
    # TODO default baseLocation above is probably not cross platform
    base = File.expand_path(baseLocation)

    if (!FileTest.exists?(base)) then
      FileUtils.mkdir_p(base)
    end
    @baseLocation = base
    @staleTolerance = staleTolerance
    @timeBetweenRequests = timeBetweenRequests 
    @lastRequestTime = nil
    @maxRetries = maxRetries
    @timeBetweenRetries = timeBetweenRetries
  end

  # Determines if data used by the given time should be considered stale or
  # not. Stale means that the data is old and should be retrieved again.
  # Returns true if the difference between the current date and +mtime+
  # is less than +@staleTolerance+. This difference is measured in days.
  def stale?(mtime)
    date = Date.new(mtime.year, mtime.month, mtime.day)
    diff = Date.today - date
    return (diff.abs < @staleTolerance)
  end

  # Makes a request to the audioscrobbler web services platform. If the
  # request has been made recently, and +cache+ is true, the request
  # will be read from the cache. Otherwise it will be executed against
  # the server and if +cache+ is true, it will be written in the cache.
  #
  # +url+ is the path element on the typical request URL.
  # For example:
  #  scrobbleRequest('/1.0/artist/birmingham+6/toptags.xml')
  #
  # +host+ is optional and can be used if you would like to make calls against
  # a different host for some reason.
  #
  # Note: elements of the url (such as band name in the above example) must
  #       be properly escaped. Use CGI.escape(bandname).
  def scrobbleRequest (url, host = 'ws.audioscrobbler.com', cache = true)

    escaped = CGI.escape(url)
#   puts "URL: #{url}"

    # Probably not WIN32 compliant (invalid chars on FAT32 file systems)
    cacheFile = @baseLocation + "/" + host + "-" + escaped
    if (cache && FileTest.exists?(cacheFile)) then
      if (stale?(File.mtime(cacheFile))) then
        array = IO.readlines(cacheFile)
        data = array.join
  #      puts "###### CACHE ######"
  #      puts data
  #      puts "######  END  ######"
        return data
      end
    end

    retries = 0
    begin
      if (retries > 0) then
        diff = Time.now - @lastRequestTime
        if (diff < @timeBetweenRetries) then
          sleep(@timeBetweenRetries)
        end
      end
      if (@lastRequestTime != nil) then
        diff = Time.now - @lastRequestTime
        if (diff < @timeBetweenRequests) then
          sleep(@timeBetweenRequests)
        end
      end

      h = Net::HTTP.new(host, 80)
      response, data = h.get(url, nil)
      @lastRequestTime = Time.now

 #     puts "###### LIVE ######"
 #     puts data
 #     puts "###### END  ######"

      if (response.code == "500") then
        raise Server500Error, "Response 500 Internal Server Error from #{host}"
      end
    rescue Server500Error => error
      if (retries <= @maxRetries) then
        retries += 1
        puts "Response 500 Internal Server Error from #{host}, retry ##{retries} in #{@timeBetweenRetries} seconds."
        retry
      else
        raise
      end
    end

    if (cache) then
      f = File.new(cacheFile, File::CREAT|File::TRUNC|File::RDWR, 0644)
      f.print(data)
      f.close
    end

    return data
  end
end
