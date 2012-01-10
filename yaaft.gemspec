# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "yaaft/version"

Gem::Specification.new do |s|
  s.name        = "yaaft"
  s.version     = Yaaft::VERSION
  s.authors     = ["rgould"]
  s.email       = ["rwgould@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{A collection of tools to help organise an MP3 collection.}
  s.description = %q{A collection of tools to help organise an MP3 collection.}

  s.rubyforge_project = "yaaft"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_dependency "mixlib-cli"
  s.add_runtime_dependency "id3lib-ruby"
  s.add_runtime_dependency "ruby-mp3info"
  s.add_development_dependency "rspec"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "aruba"
end
