# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grut/version'

Gem::Specification.new do |spec|
  spec.name          = 'grut'
  spec.version       = Grut::VERSION
  spec.authors       = ['Andrey Koleshko']
  spec.email         = ['ka8725@gmail.com']

  spec.summary       = %q{Flexible authorization solution.}
  spec.description   = %q{
                         Thi is an authorization system for a Ruby (including Rails) project,
                         that allows to specify dynamic permissions. All data is stored
                         in an SQL database, supported by Sequel.
                       }
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|config|bin)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'pg'
  spec.add_dependency 'sequel'
end
