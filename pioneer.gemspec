# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pioneer/version"

Gem::Specification.new do |s|
  s.name        = "pioneer"
  s.version     = Pioneer::VERSION
  s.authors     = ["Petr"]
  s.email       = ["pedro.yanoviches@gmail.com"]
  s.homepage    = ""
  s.summary     = "HTTP crawler"
  s.description = "Simple async HTTP crawler based on em-synchrony"

  s.rubyforge_project = "pioneer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "yajl-ruby"
  s.add_development_dependency "nokogiri"
  s.add_runtime_dependency "em-synchrony"
  s.add_runtime_dependency "em-http-request"
end
