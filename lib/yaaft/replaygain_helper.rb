module Yaaft
  class ReplayGainHelper
    def self.has_tags?(mp3info)
      return false if mp3info.tag2.RVA2.nil?
      # see http://www.id3.org/id3v2.4.0-frames for RVA2 definition.
      # replaygain tags in RVA2 usually have multiple entries
      # one for "track" and one for "album". We require both.

      if mp3info.tag2.RVA2.respond_to? :select
        mp3info.tag2.RVA2.select{|s| s =~ /^(track|album)/i }.length == 2
      else
        # it's probably a String, meaning only one of track or album. We want both.
        false
      end
    end

    def self.apply_tags(mp3info)
      true
    end
  end
end
