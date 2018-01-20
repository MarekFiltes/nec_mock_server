# coding: utf-8
$:.push File.expand_path('../lib', __FILE__)

lp = File.expand_path(File.dirname(__FILE__))
unless $LOAD_PATH.include?(lp)
  $LOAD_PATH.unshift(lp)
end

require "nec_mock_server/version"

Gem::Specification.new do |spec|
  spec.name          = "nec_mock_server"
  spec.version       = NECMockServerHelper::VERSION
  spec.authors       = ["Marek Filteš"]
  spec.email         = ["marek.files@gmail.com"]

  spec.summary       = "NEC Mock Server"
  spec.description   = "NEC helper gem to create Unit Test mock server of sub application"
  spec.license       = "MIT"

  spec.require_paths = ["lib"]
  spec.files         = Dir["lib/**/*.*"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
end
