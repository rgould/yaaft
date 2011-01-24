require 'cgi'
require 'net/http'
require "rexml/document"
require 'rubygems'
require 'mp3info'
require 'jcode'
require 'session'

$KCODE = 'u'

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

module YAAFT
class Validator

  class ArtistNotFoundException < RuntimeError
  end
  
  def initialize(cache, options)
    @notest = options["notest"]
    @recursive = options["recursive"]
    @verbose = options["verbose"]
    @auto = options["auto"]
    
    @tolerance = 39
    @cache = cache
    @overrides = ["industrial", "metal", "seen live", "synth", "futurepop", "jazz", "electronic", "electro", "electro-industrial", "world", 
"world music", "World music", "female fronted metal", "dark", "ambient", "experimental", "drone"]
    @genreCaseFix = {
      "ebm" => "EBM",
      "new wave" => "New Wave",
      "avant-garde metal" => "Avant-Garde Metal",
      "avant-garde" => "Avant-Garde",
      "avantgarde" => "Avant-Garde",
      "power metal" => "Power Metal",
      "folk rock" => "Folk Rock",
    	"death metal" => "Death Metal",
    	"rhythmic noise" => "Rhythmic Noise",
      "gothic metal" => "Gothic Metal",
      "black metal" => "Black Metal",
      "folk metal" => "Folk Metal",
      "viking metal" => "Viking Metal",
      "doom metal" => "Doom Metal",
    	"dark wave" => "Darkwave",
      "symphonic metal" => "Symphonic Metal",
      "melodic death metal" => "Melodic Death Metal",
      "progressive metal" => "Progressive Metal",
      "industrial metal" => "Industrial Metal",
      "industrial rock" => "Industrial Rock",
      "gothic rock" => "Gothic Rock",
    	"progressive rock" => "Progressive Rock",
      "dark ambient" => "Dark Ambient",
      "martial industrial" => "Martial Industrial",
      "female fronted metal" => "Female Fronted Metal",
      "medieval" => "Mittelalter",
    	"dark electro" => "Dark Electro",
    	"post-rock" => "Post-Rock",
    	"noise" => "Powernoise",
    	"power noise" => "Powernoise",
    	"idm" => "IDM",
      "power electronics" => "Powerelectronics",
    	"post-punk" => "Post-Punk"
    }
  end

  def makeTagRequest(bandname)
    data = @cache.scrobbleRequest('/1.0/artist/'+bandname+'/toptags.xml')
    if (data =~ /^No artist exists with this name/ || data =~ /404 Not Found/)
      raise ArtistNotFoundException.new, "Artist not found: #{bandname}", caller
    end
    return data
  end

  def retrieveTags(bandname)
    data = makeTagRequest(bandname)

    tags = Hash.new

    doc = REXML::Document.new data
    doc.elements.each("toptags/tag") { |element| 
      weight = element.elements["count"].text.to_i;
      tags[element.elements["name"].text] = weight;
    }

    return tags;
  end

  # This is the previous implementation of retrieveBandname, which is now broken.
  # When the last.fm API provides for looking up the 'proper name' of an 
  # artist, then we can go back to this code.
  # see: http://www.last.fm/group/Last.fm+Web+Services/forum/21604/_/546933
  def retrieveBandnameOld(bandname)
    data = makeTagRequest(bandname)
    begin
      doc = REXML::Document.new data
      root = doc.root
      return root.attributes["artist"]
    rescue
      puts "Error while parsing XML. Dumping data:"
      puts "###### BEGIN DATA ######"
      puts data
      puts "###### END DATA ######"
      raise
    end
  end

  def retrieveBandname(bandname)
    url = "/music/#{bandname}"

    h = Net::HTTP.new('www.last.fm', 80)
    response, data = h.get(url, nil)

#      puts "URL: #{url}\n"
#      puts "RESPONSE: #{response.code}\n"

    if (response.code == "200") then
        # exact match, no redirection
        return CGI.unescape(bandname)
    end

    newurl = response["location"]

    newurl =~ /([^\/]*)$/
    result = $1

    return CGI.unescape(result)
  end

  def findHighestTags(tags)
    highestValue = -1;
    highestKeys = nil
    tags.each { |key, value|
      if (value > highestValue) then
        highestValue = value
        highestKeys = Array.new
        highestKeys.push key
      elsif (value == highestValue) then
        highestKeys.push key
      end
    }

    return highestKeys
  end

  def stripOverrides(tags)
    @overrides.each {|value|
      remove = false
      count = tags[value];
      if (count == nil) then
        next
      end
      tags.each { |key, weight| 
        if (key != value) then
          key = key.downcase
          if (weight > count) then
            remove = true
            break
          end
          diff = count - weight
          if (diff < @tolerance) then
            remove = true
            break
          end
          remove = false
        end
      }
      if (remove) then
#          puts "Removing override #{value}\n"
        tags.delete value
      else
        puts "Preserving tag #{value}\n"
      end
    }
    return tags
  end

  def processFiles(files) 
    files.each { |file| 
      if (!FileTest.exists?(file)) then
        raise "Cannot find file: #{file}."
      end
      processFile(file)
    }
  end

  def processFile(file)
    if (FileTest.directory?(file)) then
      if (@recursive) then
        Dir.foreach(file) {|f|
          if (f != "." && f != "..") then
            fullPath = File.expand_path(File.join(file, f))
            processFile(fullPath)
          end
        }
      else
        # file is a directory, but we are not recursing. ignore it.
        puts "Ignoring directory: #{file}" if @verbose          
        return
      end
    end
    
    mp3 = Mp3Info.open(file, :encoding => 'utf-8')
    
    if (mp3.bitrate < 192) then
      #Mp3Info calculates average bitrate if the file has a XING vbr header
      puts("Problem: #{file} has bitrate #{mp3.bitrate}. It probably sounds like crap!\n")
    end
    
    if (mp3.tag.empty?) then
      puts "File has no id3 v1 or v2 tags: #{file}\n"
      return
    end
    
    if (!mp3.tag1.empty? and mp3.tag2.empty?) then
      # copy v1 to v2, delete v1
      puts "Problem: #{file}: has v1 tag but no v2 tag."
      if (@notest) then
        tag2.artist   = tag1.artist
        tag2.album    = tag1.album
        tag2.title    = tag1.title
        tag2.tracknum = tag1.tracknum
        tag2.year     = tag1.year
        tag2.genre    = tag1.genre #probably not best way to do it
        tag2.comment  = tag1.comment
        mp3.removetag1
      end
    elsif (!mp3.tag1.empty? and !mp3.tag2.empty?) then
      # compare v1 to v2, raise flag if they differ or delete v1
      tag1 = mp3.tag1
      tag2 = mp3.tag2
      if (tag1.artist != tag2.artist || 
          tag1.album != tag2.album || 
          tag1.title != tag2.title ||
          tag1.tracknum != tag2.tracknum ||
          tag1.year != tag2.year ||
          tag1.genre != tag2.genre ||
          tag1.comment != tag2.comment) then
          # if tag1.title is a shortened version of tag2.title, that's okay (same for other tags)
          # if genres don't match, just use tag2, as it will probably get clobbered later
          puts "Problem: #{file}: Has both v1 and v2 tags, but they differ.\n"
      elsif (@notest)
        mp3.removetag1
      end
    end
    
    if (mp3.tag2.RVA2.nil?) then
#TODO check for both Track and Album gain info
      puts "Problem: #{file}: missing ReplayGain information\n"
      if (@notest) then
        shell = Session.new
        stdout, stderr = shell.execute 'mp3gain -v'
        (stderr =~ /version 1.(\d).(\d)/)
        if ( ($1.to_i == 5 and $2.to_i < 2) or ($1.to_i < 5) ) then
          puts "Can't store ReplayGain tags as ID3 unless you have mp3gain >= 1.5.2."
        else
          #TODO probably want to do this the entire album at the same time!
          puts "Running mp3gain -s i #{file}"
          shell = Session.new

          stdout, stderr = shell.execute("mp3gain -s i \"#{file}\"")
#            puts stdout
#            puts stderr
#            puts shell.exitstatus
          if (shell.exitstatus != 0) then
            puts "Error invoking mp3gain on #{file}: #{stderr}"
          end
        end
      end
    end        

    if (mp3.tag.artist.nil?) then
      puts "Problem: #{file}: missing tag: artist\n"
    end

    if (mp3.tag.album.nil?) then
      puts "Problem: #{file}: missing tag: album\n"
    end

    if (mp3.tag.title.nil?) then
      puts "Problem: #{file}: missing tag: title\n"
    end

    if (mp3.tag.tracknum.nil?) then
      puts "Problem: #{file}: missing tag: track number\n"
    end

    if (mp3.tag.year.nil?) then
      puts "Problem: #{file}: missing tag: year\n"
    end

    if (mp3.tag.genre_s.nil?) then
      puts "Problem: #{file}: missing tag: genre\n"
    end

    # attempt to automatically lookup missing tags
    # check tags for bad unicode

    mp3.tag.each { |key, value| 
      if (!isValidUTF8(value)) then
          puts "Problem: #{file}: bad unicode in tag #{key}: #{value}"
      end
    }

    # check filename for bad unicode
    # fix artist
    # fix genre
    # fix track
    # check filename matches good format
    # check for presence of album art on discogs and here

  end
  
  def fixGenres(files)
    files.each { |file|
      if (!FileTest.exists?(file)) then
        raise "Cannot find file: #{file}."
      end
      fixGenre(file)
    }
  end
  
  def fixGenre(file)
  
    if (FileTest.directory?(file)) then
      if (@recursive) then
        Dir.foreach(file) {|f|
          if (f != "." && f != "..") then
            fullPath = File.expand_path(File.join(file, f))
            fixGenre(fullPath)
          end
        }
      else
        # file is a directory, but we are not recursing. ignore it.
        puts "Ignoring directory: #{file}" if @verbose          
        return
      end
    end
  
    mp3 = Mp3Info.open(file, :encoding => 'utf-8')

#      if (tag == nil || (!tag.has_tag?(ID3Lib::V1) && !tag.has_tag?(ID3Lib::V2))) then
#        puts "No tags found for '#{filename}'\n"
#        return
#      end
#      artist = tag.artist
    artist = mp3.tag.artist
    if (artist == "" || artist == nil) then
      puts "\tFile has id3 tag, but no artist entry: #{file}\n"
      return
    end
    genre = lookupGenre(artist)
    if (genre == nil) then
      puts "Unable to find genre for '#{file}'\n"
      return
    end

    genre = genre.downcase
    caseFixed = @genreCaseFix[genre]
    if (caseFixed != nil) then
      genre = caseFixed
    else
      genre = genre.capitalize
    end
    if (@notest && @auto) then
      mp3.tag.genre_s = genre
      puts "#{artist} => #{genre}\n"
#        tag.update!
      mp3.close
    elsif (@notest && !@auto) then
      print "\t#{artist}: #{mp3.tag.genre_s} => #{genre}, change? (Y/n): "
      query = STDIN.gets
      query.chomp!
      if (query =~ /^[Nn]/) then
        return
      end
      mp3.tag.genre_s = genre
#        tag.update!        
      mp3.close
    else
      puts "Should change: #{artist}: #{mp3.tag.genre_s} => #{genre}"
    end
  end

  def fixArtists(files)
    files.each { |file|
      if (!FileTest.exists?(file)) then
        raise "Cannot find file: #{file}."
      end
      fixArtist(file)
    }
  end
  
  def fixArtist(file)
  
    if (FileTest.directory?(file)) then
      if (@recursive) then
        Dir.foreach(file) {|f|
          if (f != "." && f != "..") then
            fullPath = File.expand_path(File.join(file, f))
            fixArtist(fullPath)
          end
        }
      else
        # file is a directory, but we are not recursing. ignore it.
        puts "Ignoring directory: #{file}" if @verbose          
        return
      end
    end
  
    puts file +":"
    mp3 = Mp3Info.open(file, :encoding => 'utf-8')

#      tag = ID3Lib::Tag.new(file)
#      if (tag == nil || (!tag.has_tag?(ID3Lib::V1) && !tag.has_tag?(ID3Lib::V2))) then
#        puts "\tNo tags found."
#        return
#      end
#      artist = tag.artist
    artist = mp3.tag.artist
    tagValue = artist
    if (artist == "" || artist == nil) then
      puts "\tFile has id3 tag, but no artist entry"
      return
    end
    begin
#        puts "Hex name: " 
#        artist.each_byte {|c| print "0x%04x " % c }
#        puts "\nEscaped name: #{CGI.escape(artist)}\n"

#        puts "Tetxenc: ", tag.frame(:TPE1)[:textenc], "\n"

      correct = retrieveBandname(CGI.escape(artist))
      if (correct == tagValue) then
        puts "\tNo changes needed."
        return
      end
      if (@notest && !@auto) then
        print "\t#{tagValue} => #{correct}, change? (Y/n): "
        query = STDIN.gets
        query.chomp!
        if (query =~ /^[Nn]/) then
          return
        end
        mp3.tag.artist = correct
        mp3.close
#          tag.artist = correct
#          tag.update!          
      elsif (@notest && @auto) then
        puts "\tChanging #{tagValue} => #{correct}"
        mp3.tag.artist = correct
        mp3.close
#          tag.artist = correct
#          tag.update!
      else
        print "\tShould perform change: #{tagValue} => #{correct}"
      end

    rescue ArtistNotFoundException
      if (@notest && !@auto) then
        print "\tArtist '#{artist}' not found on last.fm. Enter a different name? [Enter to skip] "
        entry = STDIN.gets
        entry.chomp!
        if (entry != "") then
          artist = entry
          retry
        end
      elsif (@notest && @auto) then
        print "\t Artist '#{artist}' not found on last.fm. Skipping."
      else
        print "\t Artist '#{artist}' not found on last.fm."
      end
    end
    puts ""
  end

  def setGenre(genre, filename)
    mp3 = Mp3Info.open(file, :encoding => 'utf-8')
    mp3.tag.genre_s = genre
    mp3.close
    
#      tag = ID3Lib::Tag.new(filename)
#      tag.genre = genre
    puts "#{filename} => #{genre}\n"
#      tag.update!
  end

  

  def lookupGenre(band)
    if (@genreCache == nil) then
      @genreCache = Hash.new
    end
    if (@genreCache[band] != nil) then
      return @genreCache[band]
    end
    if (band == "Various Artists" || band == "Various Artist" || band == "VA") then
      puts "Found artist '#{band}'! Fix your tags you gimboid!\n"
      return nil
    end
    tags = retrieveTags(CGI.escape(band))
    if (tags.length == 0) then
      puts "Artist '#{band}' has no tags on Last.fm!\n"
      return nil
    end
    tags = stripOverrides(tags)
    tags = findHighestTags(tags)
    if (tags.length == 1) then
      return tags.pop
    end

    puts "Multiple tags found for " + band + ": "
    i = 0;
    tags.each { |tag|
      puts "\t#{i += 1}\t" + tag
    }
    print "Which should I choose? [" + tags.first + "] "
    while entry = STDIN.gets
      entry.chomp!
      if (entry == "") then
        chosen = tags.first
      elsif (entry =~ /^\d*$/ && entry.to_i-1 < tags.length && entry.to_i > 0) then
        return tags[entry.to_i-1]
      else
        chosen = closestMatch(entry, tags)
      end
      if (chosen != nil) then
        break;
      end
      print "Ambiguous choice. Enter a tag or number: [" + tags.first + "] "
    end

    @genreCache[band] = chosen
    return chosen
  end

  def closestMatch(string, collection)
    diff = nil
    match = nil
    collection.each { | value |
      same = sameChars(string, value)
      if (diff == nil || same.length > diff) then
        diff = same.length
        match = value
      elsif (diff == same.length) then
        #ambigious
        return nil
      end
    }
    if (diff == 0) then
      return nil
    end
    return match
  end

  def sameChars(string1, string2)
    same = ""
    for num in (0..string1.length)
      if string1[num, 1] == string2[num, 1] then
        same = same + string1[num, 1]
      end
    end
    return same
  end

  # determines whether the given input is a valid UTF8 string or not
  # input is assumed to be UTF8 already. 
  #
  # returns false if the string contains invalid UTF8 characters,
  # true otherwise
  #
  # see http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
  def isValidUTF8(string) 
    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
#      puts("String: #{string}")
    valid = ic.iconv(string.to_s + ' ')[0..-2]
#      puts("Valid: #{valid}")
    return string.to_s == valid
  end

end
end
