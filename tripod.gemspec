# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tripod/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["RicSwirrl"]
  gem.email         = ["ric@swirrl.com"]
  gem.description   = %q{RDF ruby ORM}
  gem.summary       = %q{Active Model style RDF ORM}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "tripod"
  gem.require_paths = ["lib"]
  gem.version       = Tripod::VERSION

  gem.required_rubygems_version = ">= 1.3.6"
  gem.rubyforge_project         = "tripod"

  gem.add_dependency "rest-client"
  gem.add_dependency "activemodel", "~> 3.1"
  gem.add_dependency "equivalent-xml"
  gem.add_dependency "rdf", "~> 0.3"
  gem.add_dependency "rdf-rdfxml"
  gem.add_dependency "rdf-n3"
  gem.add_dependency "rdf-json"
end
