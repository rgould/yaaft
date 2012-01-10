require 'mixlib/cli'

module Yaaft
  class CLI
    include Mixlib::CLI

    def bitrate(files)
      files.each do |f|
#      puts Yaaft::BitrateAnalyser.analyse(files)
      end
    end

    def run(argv=ARGV)
      parse_options(argv)
      bitrate(argv)
    end
  end
end
