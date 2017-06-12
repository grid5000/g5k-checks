#!/usr/bin/env ruby

NAME = "g5kchecks"

puts 'Installing vendored g5k-checks dependencies...'

#Remove saved bundler options
system("rm -fr ./.bundle")
system 'bundle install --standalone --no-binstubs --without=development --path bundle'

abort "No bundle installed" unless Dir.exist? 'bundle'

RUBY_INSTALL_ROOT = '/usr/lib/ruby'

#Override bundle-generated setup.rb
#Gem native extensions load paths are generated relative to current directory, which is incorrect
File.open "bundle/bundler/setup.rb", "w" do |f|
  f.puts "deps_root = '#{RUBY_INSTALL_ROOT}/bundles/#{NAME}'"

  Dir["bundle/ruby/**/lib"].each do |dir|
    dir = dir.gsub('bundle/', '')
    f.puts %Q[$:.unshift "\#{deps_root}/#{dir}"]
  end
end
