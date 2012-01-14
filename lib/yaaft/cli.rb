require 'mixlib/cli'
require 'yaaft'

module Yaaft
  class CLI
    include Mixlib::CLI

    option :help,
      short: "-h",
      long: "--help",
      on: :tail,
      boolean: true,
      show_options: true,
      exit: 0

    option :version,
      short: "-v",
      long: "--version",
      on: :tail,
      description: "Show yaaft version and exit",
      boolean: true

    def run(argv=ARGV)
      args = parse_options(argv)

      if config[:version]
        puts Yaaft::VERSION
        exit 0
      end

      case args.shift
      when "bitrate"
        explodeFiles(args).flatten.each do |f|
          bitrate(f)
        end
      else
        puts "Unknown subcommand. Try --help"
      end
    end

    def bitrate(file)
      mp3info = Mp3Info.open(file, :encoding => 'utf-8')
      print "#{file}... "
      if Yaaft::BitrateAnalyser.analyse(mp3info)
        puts "OK"
      else
        print "low bitrate: #{mp3info.bitrate}kbps"
        print " vbr" if mp3info.vbr
        print "\n"
      end
    end

    def explodeFiles(files, curr_path = "")
      files.flat_map do |f|
        file = if curr_path == "" then f else "#{curr_path}/#{f}" end
        abort "No such file or directory: #{file}" unless FileTest.exists?(f)
        if f == "." || f == ".."
          nil
        elsif FileTest.directory?(file)
          explodeFiles(Dir.foreach(file), file).reject{|a| a.nil?}
        else
          file
        end
      end
    end
  end
end
