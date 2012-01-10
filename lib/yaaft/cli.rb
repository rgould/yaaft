require 'mixlib/cli'
require 'yaaft'

module Yaaft
  class CLI
    include Mixlib::CLI

    def bitrate(file)
      mp3info = Mp3Info.open(file, :encoding => 'utf-8')
      if Yaaft::BitrateAnalyser.analyse(mp3info)
        puts "#{file}... OK"
      else
        puts "#{file}... low bitrate!"
      end
    end

    def run(argv=ARGV)
      args = parse_options(argv)
      case args.shift
      when "bitrate"
        explodeFiles(args).flatten.each do |f|
          bitrate(f)
        end
      else
        puts "Unknown subcommand. Try --help"
      end
    end

    def explodeFiles(files)
      files.map do |f|
        abort "No such file or directory: #{f}" unless FileTest.exists?(f)
        if FileTest.directory?(f)
          explodeFiles(Dir.foreach(f))
        else
          f
        end
      end
    end
  end
end
