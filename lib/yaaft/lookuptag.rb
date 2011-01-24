#!/usr/bin/ruby

# == Usage
#
#  lookuptag.rb [OPTION]... artistfix FILE...
#
#  -h, --help:            show this help and exit
#  -r, --recursive:       recursively parse directories
#  -c, --cache=DIRECTORY: specify the directory to be used for the last.fm cache
#                         defaults to ~/.scrobbleCache
#
#  artistfix: For each file, check for an id3 tag. If found, look up the
#             artist's name on last.fm. Change the tag to agree with the
#             information retrieved.

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

require "yaaft/yaaft"
require "yaaft/scrobbleCache"
require 'getoptlong'
require 'rdoc/usage'
require 'id3lib'

# beware link-loops?
def processArtistFix (file, recursive, lastfm)
  if (FileTest.directory?(file)) then
    if (recursive) then
      Dir.foreach(file) {|f|
        if (f != "." && f != "..") then
          fullPath = File.expand_path(File.join(file, f))
          processArtistFix(fullPath, recursive, lastfm)
        end
      }
    end
  else
    lastfm.artistFix(File.expand_path(file))
  end
end

def processGenreFix (file, recursive, lastfm)
  if (FileTest.directory?(file)) then
    if (recursive) then
      Dir.foreach(file) {|f|
        if (f != "." && f != "..") then
          fullPath = File.expand_path(File.join(file, f))
          processGenreFix(fullPath, recursive, lastfm)
        end
      }
    end
  else
    begin
      lastfm.genreFix(File.expand_path(file))
    rescue
      puts "Crapped out on file: #{file}\n"
      raise
    end
  end
end

def rename(file, recursive)
  if (FileTest.directory?(file)) then
    if (recursive) then
      Dir.foreach(file) {|f|
        if (f != "." && f != "..") then
          fullPath = File.expand_path(File.join(file, f))
          rename(fullPath, recursive)
        end
      }
    end
  else
    puts file+":"
    tag = ID3Lib::Tag.new(file)
    if (tag == nil || (!tag.has_tag?(ID3Lib::V1) && !tag.has_tag?(ID3Lib::V2))) then
      puts "\tNo tags found."
      return
    end
    track = tag.track
    title = tag.title
    if (track == nil || track == "") then
      puts "\tTag found, but track is empty."
      return
    elsif (title == nil || title == "") then
      puts "\tTag found, but title is empty."
      return
    end

    if (track.length == 1) then
      track = "0"+track
    end

    newName = "#{track}. #{title}.mp3"
		puts "Old: #{file}\nNew: #{newName}"
		if (File.exist?(newName)) then
			puts "File already exists! Aborting renaming file #{file}"
			return
		end
		File.rename(file, newName)
  end
end

def processSetGenre (genre, file, recursive, lastfm)
  if (FileTest.directory?(file)) then
    if (recursive) then
      Dir.foreach(file) {|f|
        if (f != "." && f != "..") then
          fullPath = File.expand_path(File.join(file, f))
          processSetGenre(genre, fullPath, recursive, lastfm)
        end
      }
    end
  else
    begin
      lastfm.setGenre(genre, File.expand_path(file))
    rescue
      puts "Crapped out on file: #{file}\n"
      raise
    end
  end
end


if __FILE__ == $0

  cache = nil
  recursive = false
  verbose = false

  opts = GetoptLong.new(
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--recursive', '-r', GetoptLong::NO_ARGUMENT ],
    [ '--verbose', '-v', GetoptLong::NO_ARGUMENT ],
    [ '--cache', '-c', GetoptLong::OPTIONAL_ARGUMENT ]
  )

  opts.each do |opt, arg|
    case opt
      when '--help'
        RDoc::usage('Usage')
      when '--recursive'
        recursive = true
      when '--verbose'
        verbose = true
      when '--cache'
        cache = ScrobbleCache.new(File.expand_path(arg), 3, 1)
    end
  end

  if (cache == nil) then
    cache = ScrobbleCache.new(File.expand_path("~/.scrobbleCache"), 3, 1)
  end
  lastfm = LastFM::LastFM.new(cache)

  command = ARGV.shift
  case command
    when 'lookup'
      if (ARGV.length == 1) then
        artist = ARGV.shift
        puts lastfm.lookupGenre(artist).to_s
      else
        ARGV.each {|artist|
          genre = lastfm.lookupGenre(artist).to_s
          puts "#{artist}: #{genre}"
        }
      end
    when 'artistfix'
      ARGV.each {|file|
        if (!FileTest.exists?(file)) then
          puts "Cannot find file: #{file}.\n"
          exit 1
        end
        processArtistFix(file, recursive, lastfm)
      }
    when 'genrefix'
      ARGV.each {|file|
        if (!FileTest.exists?(file)) then
          puts "Cannot find file: #{file}.\n"
          exit 1
        end
        processGenreFix(file, recursive, lastfm)
      }
		when 'rename'
			ARGV.each {|file|
				if (!FileTest.exist?(file)) then
					puts "Cannot find file: #{file}.\n"
					exit 1
				end
				rename(file, recursive)
		  }
    when 'setgenre'
      genre = ARGV.shift
      if (genre == nil || genre == "") then
        puts "Invalid parameters. Provide a genre and some target files.\n";
        exit 1
      end
      puts "Using genre '#{genre}'\n"
      if (ARGV.length < 0) then
        puts "No targets for setgenre. Specify one or more files\n"
        exit 1
      end
      ARGV.each {|file|
        if (!FileTest.exist?(file)) then
          puts "Cannot find file: #{file}.\n"
          exit 1
        end
        processSetGenre(genre, file, recursive, lastfm)
      }
    else
      puts "Unknown command: #{command}."
      exit 1
  end
end
