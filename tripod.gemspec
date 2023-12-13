# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tripod/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ric Roberts", "Bill Roberts", "Asa Calow"]
  gem.email         = ["ric@swirrl.com"]
  gem.description   = %q{RDF ruby ORM}
  gem.summary       = %q{Active Model style RDF ORM}
  gem.homepage      = "http://github.com/Swirrl/tripod"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "tripod"
  gem.require_paths = ["lib"]
  gem.license       = 'MIT'
  gem.version       = Tripod::VERSION

  gem.required_rubygems_version = ">= 1.3.6"

  gem.add_dependency "rest-client"
  gem.add_dependency "activemodel", ">= 5.2", "<= 6.2"
  gem.add_dependency "activesupport", ">= 5.2", "<= 6.2"
  gem.add_dependency "equivalent-xml"
  gem.add_dependency "rdf", ">= 3.2.0", "<=3.3.0"
  gem.add_dependency "rdf-rdfxml", ">= 3.2.0", "<=3.3.0"
  gem.add_dependency "rdf-turtle", ">= 3.2.0", "<=3.3.0"
  gem.add_dependency "rdf-json", ">= 3.2.0", "<=3.3.0"
  gem.add_dependency "json-ld", "~> 3.3.1"
  gem.add_dependency "guid"
  gem.add_dependency "dalli", "~> 2.7.0"
  gem.add_dependency "connection_pool", "~> 2.2"
end
