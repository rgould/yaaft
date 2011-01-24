require "test/unit"
require 'cgi'
require 'net/http'
require 'rexml/document'
require '../lib/yaaft/yaaft'
require "../lib/yaaft/scrobbleCache"

# tests the LastFM module to determine if LastFM has unexpectidly changed 
# functionality on us. 

class TestUTF8 < Test::Unit::TestCase

  def test_utf8

    bad = "tag� Budapest"
  
    yaaft = YAAFT::YAAFT.new(ScrobbleCache.new)

    result = yaaft.isValidUTF8(bad)
    expected = false

    assert_equal(expected, result, "isValidUTF8 is broken, input was #{bad}")

    good = "☭☹☯☼ßü°åłşţ"
    result = yaaft.isValidUTF8(good)
    expected = true

    assert_equal(expected, result, "isValidUTF8 is broken, input was #{good}")

  end

end

