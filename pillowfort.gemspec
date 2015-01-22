$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "pillowfort/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "pillowfort"
  s.version     = Pillowfort::VERSION
  s.authors     = ["Tim Lowrimore"]
  s.email       = ["tlowrimore@coroutine.com"]
  s.homepage    = "github.com/coroutine/pillowfort"
  s.summary     = "Opinionated, session-less API authentication"
  s.description = "Opinionated, session-less API authentication"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails",   "~> 4.2.0"
  s.add_dependency "bcrypt",  "~> 3.1.7"
end
