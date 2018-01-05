# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pixiurge/version'

Gem::Specification.new do |spec|
  spec.name          = "pixiurge"
  spec.version       = Pixiurge::VERSION
  spec.authors       = ["Noah Gibbs"]
  spec.email         = ["the.codefolio.guy@gmail.com"]

  spec.summary       = %q{Pixiurge is a simple creation platform for browser-based simulation games.}
  spec.description   = %q{Pixiurge is a creation platform for browser-based simulation games. It uses the Pixi.js browser libraries and a combination of Demiurge, Websockets and Ruby DSLs on the server side.}
  spec.homepage      = "https://github.com/noahgibbs/pixiurge"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_runtime_dependency "demiurge", "~> 0.2.0"
  spec.add_runtime_dependency "thin", "~> 1.7"
  spec.add_runtime_dependency "faye-websocket", "~> 0.10"
  spec.add_runtime_dependency "multi_json", "~> 1.12"
  spec.add_runtime_dependency "tmx", "~> 0.1.5"
  spec.add_runtime_dependency "therubyracer", "~> 0.12"
  spec.add_runtime_dependency "rack-coffee", "~> 1.0"
end
