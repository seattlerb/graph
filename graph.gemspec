# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "graph"
  s.version     = '0.0.1'
  s.authors     = ["Ian Steel"]
  s.email       = ["houdi84@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Updated version of Graph to support reverse direction edges}
  s.description = %q{Updated version of Graph to support reverse direction edges}

  s.rubyforge_project = "graph"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
