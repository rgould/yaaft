# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{yaaft}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Richard Gould"]
  s.autorequire = %q{yaaft}
  s.date = %q{2009-05-24}
  s.description = %q{A collection of tools to help organise an MP3 collection.}
  s.email = %q{rwgould@gmail.com}
  s.executables = ["yaaft", "artistfix", "genrefix"]
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/yaaft", "lib/yaaft/yaaft.rb", "lib/yaaft/setgenre.rb", "lib/yaaft/lastfm.rb", "lib/yaaft/scrobbleCache.rb", "lib/yaaft/genreTagger.rb", "lib/yaaft/lookuptag.rb", "lib/yaaft.rb", "spec/yaaft_spec.rb", "spec/spec_helper.rb", "bin/genrefix", "bin/yaaft", "bin/artistfix"]
  s.has_rdoc = true
  s.homepage = %q{http://rgould.ca}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A collection of tools to help organise an MP3 collection.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<id3lib-ruby>, [">= 0"])
    else
      s.add_dependency(%q<id3lib-ruby>, [">= 0"])
    end
  else
    s.add_dependency(%q<id3lib-ruby>, [">= 0"])
  end
end
