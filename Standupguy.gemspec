# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'Standupguy/version'

Gem::Specification.new do |spec|
  spec.name          = "Standupguy"
  spec.version       = "0.0.3"
  spec.authors       = ["Adam Panzer"]
  spec.email         = ["apanzerj@gmail.com"]
  spec.summary       = %q{Manage your StandUp quickly and easily}
  spec.description   = %q{Integrating with Zendesk. Manage your daily StandUp report easily.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-nc"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "semver"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "coveralls"

  spec.add_runtime_dependency "zendesk_api"
  spec.add_runtime_dependency "launchy"
  spec.add_runtime_dependency "haml"
end
