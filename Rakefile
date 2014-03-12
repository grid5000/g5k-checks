# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: 2013-07-05 18:48:14 +0200
#

ROOT_DIR = File.expand_path(File.dirname(__FILE__))
CHANGELOG_FILE = File.join(ROOT_DIR, "debian", "changelog")
VERSION_FILE = File.join(ROOT_DIR, "VERSION")

NAME = "g5kchecks"
USER_NAME = %x{git config --get user.name}.chomp
USER_EMAIL = %x{git config --get user.email}.chomp
VERSION = File.read(VERSION_FILE).chomp
APT = ENV['HOST'] || 'apt.grid5000.fr'

class String
  def yellow
    "\033[33m#{self}\033[0m"
  end
  def green
    "\033[32m#{self}\033[0m"
  end
  def blod
    "\033[1m#{self}\033[22m"
  end
  def red
    "\033[31m#{self}\033[0m"
  end
end

def bump(index)
  fragments = VERSION.split(".")
  fragments[index] = fragments[index].to_i+1
  ((index+1)..2).each{|i| fragments[i] = 0 }
  new_version = fragments.join(".")

  changelog = File.read(CHANGELOG_FILE)
  last_commit = changelog.scan(/\s+\* ([a-z0-9]{7}) /).flatten[0]

  cmd = "git log --oneline"
  cmd << " #{last_commit}..HEAD" unless last_commit.nil?
  content_changelog = [
    "#{NAME} (#{new_version}) sid; urgency=low",
    "",
    `#{cmd}`.split("\n").reject{|l| l =~ / v#{VERSION}/}.map{|l| "  * #{l}"}.join("\n"),
    "",
    " -- #{USER_NAME} <#{USER_EMAIL}>  #{Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")}",
    "",
    changelog
  ].join("\n")

  content_version = File.read(VERSION_FILE).gsub(VERSION,new_version)

  File.open(VERSION_FILE, "w+") do |f|
    f << content_version
  end

  File.open(CHANGELOG_FILE, "w+") do |f|
    f << content_changelog
  end

  puts "Generated changelog for version #{new_version}."
  unless ENV['NOCOMMIT']
    puts "--> Committing changelog and version file...".green
    sh "git commit -m 'v#{new_version}' #{CHANGELOG_FILE} #{VERSION_FILE}"
    sh "git tag #{File.read(VERSION_FILE).chomp}"
  end
end

task :default do
  sh "rake -T"
end

namespace :package do
  namespace :bump do
    desc "[#{VERSION.green}] Increment the patch fragment of the version number by #{'1'.blod.yellow}"
    task :patch do
      bump(2)
    end
    desc "[#{VERSION.green}] Increment the minor fragment of the version number by #{'1'.blod.yellow}"
    task :minor do
      bump(1)
    end
    desc "[#{VERSION.green}] Increment the major fragment of the version number by #{'1'.blod.yellow}"
    task :major do
      bump(0)
    end
  end

  desc "Build the binary package (#{NAME} v#{VERSION})"
  task :build do
    puts "--> Build package".green
    sh "debuild"
  end

  desc "Publish #{"#{NAME}-#{VERSION}".green} in APT repository"
  task :publish => [:build] do
    puts "--> Upload to #{APT}".green
    pkg = " #{NAME}_#{VERSION}_all.deb #{NAME}_#{VERSION}.dsc"
    pkg += " #{NAME}_#{VERSION}_amd64.changes #{NAME}_#{VERSION}.tar.gz #{NAME}_#{VERSION}_amd64.build"
    sh "cd ..;scp #{pkg} #{APT}:/tmp"
    puts "--> Move packages to incoming directory".green
    sh "ssh #{APT} 'cd /tmp;sudo mv #{pkg} /var/www/debian/incoming/'"
    puts "--> Run debarchiver (sid main)".green
    sh "ssh #{APT} 'sudo /usr/bin/debarchiver --scanall --configfile /etc/debarchiver.conf --index -a'"
  end
end
