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
end
