require "test/unit"
require 'cgi'
require 'net/http'
require 'rexml/document'
require '../lib/yaaft/yaaft'
require "../lib/yaaft/scrobbleCache"

# tests the LastFM module to determine if LastFM has unexpectidly changed 
# functionality on us. 

class TestArtistfix < Test::Unit::TestCase

  def test_artistfix

    # Look up "Welle Erdball". System should return "Welle:Erdball"
    bad = "Welle Erdball"
    badE = CGI.escape(bad)
    expected = "Welle:Erdball"
  
    yaaft = YAAFT::YAAFT.new(ScrobbleCache.new)

    result = yaaft.retrieveBandname(badE)

    assert_equal(expected, result, "Artist fix is broken")

    bad = "KMFDM"
    badE = CGI.escape(bad)
    expected = "KMFDM"

    result = yaaft.retrieveBandname(badE)
    
    assert_equal(expected, result, "Artist fix is broken")
  end

  def test_tempfix
    bad = "Welle Erdball"
    badE = CGI.escape(bad)
    expected = "Welle:Erdball"

    url = "/music/#{badE}"

    h = Net::HTTP.new('www.last.fm', 80)
    response, data = h.get(url, nil)

    assert_equal("301", response.code, "Last.fm did not return a 301 - moved permanently")

    newurl = response["location"]
    # example: http://www.last.fm/music/Welle%3AErdball

    newurl =~ /([^\/]*)$/

    resultE = $1

    assert_equal(expected, CGI.unescape(resultE))
  end

  def test_lastfm

    # Make a call to last fm to see if their system is working yet. If it is
    # working, throw an exception so we can fix our code. Make a call with both
    # the 1.0 and 2.0 APIs

    #
    # 1.0 Call
    #

    bad = "Welle Erdball"
    badE = CGI.escape(bad)
    expected = "Welle:Erdball"
  
    result = getBandname(badE)

    assert_not_equal(expected, result, "Last.fm API 1.0 is working now")

    #
    # 2.0 Call
    # 

    url = "/2.0/?method=artist.getinfo&artist=#{badE}&api_key=b25b959554ed76058ac220b7b2e0a026"
    data = ScrobbleCache.new.scrobbleRequest(url)
    doc = REXML::Document.new data
    result = doc.root.elements["artist"].elements["name"].text

    assert_not_equal(expected, result, "Last.fm API 2.0 is working now")

  end

  #### UTILITY METHODS ####

  def getBandname(bandname)
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

  def makeTagRequest(bandname)
    data = ScrobbleCache.new.scrobbleRequest('/1.0/artist/'+bandname+'/toptags.xml')
    if (data =~ /^No artist exists with this name/ || data =~ /404 Not Found/)
      raise ArtistNotFoundException.new, "Artist not found: #{bandname}", caller
    end
    return data
  end
       
end

