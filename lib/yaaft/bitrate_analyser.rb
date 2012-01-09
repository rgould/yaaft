module Yaaft
  class BitrateAnalyser
    def self.analyse(mp3info)
      mp3info.bitrate >= 192
    end
  end
end
