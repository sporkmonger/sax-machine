lib_dir = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$:.unshift(lib_dir)
$:.uniq!

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'

begin
  require 'spec/rake/spectask'
rescue LoadError
  STDERR.puts 'Please install rspec:'
  STDERR.puts 'sudo gem install rspec'
  exit(1)
end

require File.join(File.dirname(__FILE__), 'lib/sax-machine', 'version')

PKG_DISPLAY_NAME   = 'SAX Machine'
PKG_NAME           = 'sporkmonger-sax-machine'
PKG_VERSION        = SAXMachine::VERSION::STRING
PKG_FILE_NAME      = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME       = "REL #{PKG_VERSION}"

PKG_AUTHOR         = 'Paul Dix'
PKG_AUTHOR_EMAIL   = 'paul@pauldix.net'
PKG_HOMEPAGE       = 'https://github.com/sporkmonger/sax-machine'
PKG_SUMMARY        = 'A declarative sax parsing library backed by Nokogiri.'
PKG_DESCRIPTION    = <<-TEXT
A declarative sax parsing library backed by Nokogiri.
TEXT

PKG_FILES = FileList[
    'lib/**/*', 'spec/**/*', 'vendor/**/*',
    'tasks/**/*', 'website/**/*',
    '[A-Z]*', 'Rakefile'
].exclude(/database\.yml/).exclude(/[_\.]git$/)

RCOV_ENABLED = (RUBY_PLATFORM != 'java' && RUBY_VERSION =~ /^1\.8/)
if RCOV_ENABLED
  task :default => 'spec:verify'
else
  task :default => 'spec'
end

WINDOWS = (RUBY_PLATFORM =~ /mswin|win32|mingw|bccwin|cygwin/) rescue false
SUDO = WINDOWS ? '' : ('sudo' unless ENV['SUDOLESS'])

Dir['tasks/**/*.rake'].each { |rake| load rake }
