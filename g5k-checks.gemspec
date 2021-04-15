# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'g5k-checks'
  s.version = '0.1'
  s.authors = ["Grid'5000"]
  s.licenses = ['CECILL-B']
  s.email = 'support-staff@lists.grid5000.fr'
  s.summary     = "Hardware verification tool for Grid'5000"
  s.description = "g5k-checks verifies that a node is matching its Grid'5000 Reference API description"
  s.homepage = 'https://github.com/grid5000/g5k-checks'
  s.files = Dir['bin/**/*'] + Dir['conf/**/*'] + Dir['lib/**/*'] + Dir['bundle/**/*']
  s.executables = ['g5k-checks']
  s.bindir = 'bin'

  s.add_runtime_dependency('ffi-yajl', ['2.3.0'])
  s.add_runtime_dependency('mixlib-cli', ['~> 1.7.0'])
  s.add_runtime_dependency('mixlib-shellout', ['= 2.2.7'])
  s.add_runtime_dependency('ohai', ['~> 8.24.0'])
  s.add_runtime_dependency('peach', ['~> 0.5.1'])
  s.add_runtime_dependency('rest-client', ['>= 0.0.0'])
  s.add_runtime_dependency('rspec', ['~> 3.5.0'])

  s.add_development_dependency('bundler')
end
