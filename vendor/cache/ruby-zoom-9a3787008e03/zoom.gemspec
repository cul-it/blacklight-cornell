# -*- encoding: utf-8 -*-
# stub: zoom 0.4.1 ruby lib
# stub: ext/extconf.rb

Gem::Specification.new do |s|
  s.name = "zoom"
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Laurent Sansonetti", "Ed Summers"]
  s.autorequire = "zoom"
  s.date = "2014-12-02"
  s.extensions = ["ext/extconf.rb"]
  s.files = ["ChangeLog", "README.md", "Rakefile", "ext/extconf.rb", "ext/rbzoom.c", "ext/rbzoom.h", "ext/rbzoomconnection.c", "ext/rbzoomoptions.c", "ext/rbzoompackage.c", "ext/rbzoomquery.c", "ext/rbzoomrecord.c", "ext/rbzoomresultset.c", "sample/hello.rb", "sample/needle.rb", "test/package_live.rb", "test/package_test.rb", "test/record-update.xml", "test/record.dat", "test/record.txt", "test/record.xml", "test/search_batch_test.rb", "test/search_test.rb", "test/thread_test.rb", "test/zebra", "test/zebra/key", "test/zebra/key/empty_file", "test/zebra/lock", "test/zebra/lock/empty_file", "test/zebra/records", "test/zebra/records/programming_ruby.xml", "test/zebra/records/programming_ruby_update.xml", "test/zebra/register", "test/zebra/register/empty_file", "test/zebra/shadow", "test/zebra/shadow/empty_file", "test/zebra/tab", "test/zebra/tab/bib1.att", "test/zebra/tab/default.idx", "test/zebra/tab/numeric.chr", "test/zebra/tab/record.abs", "test/zebra/tab/string.chr", "test/zebra/tab/usmarc.mar", "test/zebra/zebra.cfg"]
  s.homepage = "http://ruby-zoom.rubyforge.org"
  s.rubygems_version = "2.2.2"
  s.summary = "Ruby/ZOOM provides a Ruby binding to the Z39.50 Object-Orientation Model (ZOOM), an abstract object-oriented programming interface to a subset of the services specified by the Z39.50 standard, also known as the international standard ISO 23950.  This version introduces ZOOM Extended Services."
end
