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

require 'scrobbleCache'
require 'setgenre'
require 'lookuptag'
require 'getoptlong'
require 'rdoc/usage'


require 'rubygems'
require 'id3lib'

if __FILE__ == $0

  cache = ScrobbleCache.new(File.expand_path("~/.scrobbleCache"), 3, 1)
  lastfm = LastFM.new(cache)

  files = Array.new
  while (!ARGV.empty?)
    arg = ARGV.shift
    files.push(arg)
  end

  files.each { |file|
    artist = determineArtist(file)
  }

  #puts lastfm.lookupGenre(cache, band).to_s
end

def determineArtist(filename)
  tag = ID3Lib::Tag.new(filename)
  artist = tag.artist;
  if (artist != nil)
    return artist
  end

  fullname = File.expand_path(filename)
  
end
