# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "zoom"
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Laurent Sansonetti", "Ed Summers"]
  s.autorequire = "zoom"
  s.date = "2014-08-15"
  s.extensions = ["ext/extconf.rb"]
  s.files = ["ext/rbzoom.c", "ext/rbzoompackage.c", "ext/rbzoomoptions.c", "ext/rbzoomrecord.c", "ext/rbzoomresultset.c", "ext/rbzoomconnection.c", "ext/rbzoomquery.c", "ext/rbzoom.h", "ext/extconf.rb", "test/search_batch_test.rb", "test/package_live.rb", "test/package_test.rb", "test/search_test.rb", "test/record.txt", "test/thread_test.rb", "test/record.xml", "test/zebra", "test/zebra/register", "test/zebra/register/empty_file", "test/zebra/tab", "test/zebra/tab/string.chr", "test/zebra/tab/bib1.att", "test/zebra/tab/numeric.chr", "test/zebra/tab/default.idx", "test/zebra/tab/usmarc.mar", "test/zebra/tab/record.abs", "test/zebra/key", "test/zebra/key/empty_file", "test/zebra/lock", "test/zebra/lock/empty_file", "test/zebra/zebra.cfg", "test/zebra/shadow", "test/zebra/shadow/empty_file", "test/zebra/records", "test/zebra/records/programming_ruby_update.xml", "test/zebra/records/programming_ruby.xml", "test/record.dat", "test/record-update.xml", "sample/needle.rb", "sample/hello.rb", "README.md", "ChangeLog", "Rakefile"]
  s.homepage = "http://ruby-zoom.rubyforge.org"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.25"
  s.summary = "Ruby/ZOOM provides a Ruby binding to the Z39.50 Object-Orientation Model (ZOOM), an abstract object-oriented programming interface to a subset of the services specified by the Z39.50 standard, also known as the international standard ISO 23950.  This version introduces ZOOM Extended Services."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
