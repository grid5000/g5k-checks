# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: 2013-07-05 18:48:14 +0200
#

$:.unshift File.join(File.dirname(__FILE__),'lib')

require 'g5kchecks/version'

ROOT_DIR = File.expand_path(File.dirname(__FILE__))
CHANGELOG_FILE = File.join(ROOT_DIR, "debian", "changelog")

PACKAGES_DIR = File.join(Dir.pwd, 'pkg')

VERSION_FILE = "lib/g5kchecks/version.rb"
VERSION = G5kChecks::VERSION

NAME = "g5k-checks"
USER_NAME = %x{git config --get user.name}.chomp
USER_EMAIL = %x{git config --get user.email}.chomp

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

  system("sed -i s/#{VERSION}/#{new_version}/ #{VERSION_FILE}")

  File.open(CHANGELOG_FILE, "w+") do |f|
    f << content_changelog
  end

  puts "Generated changelog for version #{new_version}."
  unless ENV['NOCOMMIT']
    puts "--> Committing changelog and version file...".green
    sh "git commit -m 'v#{new_version}' #{CHANGELOG_FILE} #{VERSION_FILE}"
    sh "git tag #{new_version}"
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

  namespace :build do

    desc "Prepare for building debian package"
    task :prepare do
      mkdir_p "#{PACKAGES_DIR}"
      sh "git archive HEAD > /tmp/#{NAME}_#{VERSION}.tar"
      Dir.chdir("/tmp") do
        mkdir_p "#{NAME}_#{VERSION}"
        sh "tar -xvf #{NAME}_#{VERSION}.tar -C #{NAME}_#{VERSION} && rm #{NAME}_#{VERSION}.tar"
      end
    end

    desc "Build debian package"
    task :debian => :prepare do
      build_dir = "/tmp/#{NAME}_#{VERSION}"
      Dir.chdir(build_dir) do
        sh "debuild --no-lintian -i -us -uc -b"
        sh "mkdir -p #{PACKAGES_DIR}"
        sh "mv #{File.expand_path('..', build_dir)}/#{NAME}_#{VERSION}_*.deb #{PACKAGES_DIR}"
        #Clean temp build files and unused targets
        sh "rm -rf #{File.expand_path('..', build_dir)}/#{NAME}*"
      end
    end
  end

  # Deprecated - Kept for manual deploy
  desc "Publish the last version (#{VERSION}) packages to packages.grid5000.fr DEPRECATED: automatically built and deployed by .gitlab-ci.yaml"
  task :publish do
    puts "Uploading package to packages.grid5000.fr ..."
    system "scp #{PACKAGES_DIR}/#{NAME}_#{VERSION}_*.deb g5kadmin@packages.grid5000.fr:/srv/packages/deb/#{NAME}/"
    puts "Updating packages list"
    system "ssh g5kadmin@packages.grid5000.fr sudo g5k-debrepo -d /srv/packages/deb/#{NAME}"
    puts "Done."
  end

end
