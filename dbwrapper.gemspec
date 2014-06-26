# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dbwrapper/version'

Gem::Specification.new do |spec|
  spec.name          = "dbwrapper"
  spec.version       = Dbwrapper::VERSION
  spec.authors       = ["Takeshi Morita"]
  spec.email         = ["takesy.morito@gmail.com"]
  spec.description   = %q{manipulatie with sqlite3,mysql,postgresql in the same way}
  spec.summary       = %q{you can use query with placeholder.  still more, multiple insert with hash array and csv backup  and csv restore.}
  spec.homepage      = "https://github.com/takeshy/dbwrapper"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
