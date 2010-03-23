#!rake
#
# Rake-TaskLibs rakefile
# 
# Copyright (c) 2008 The FaerieMUD Consortium
#
# Authors:
#  * Michael Granger <ged@FaerieMUD.org>
#

BEGIN {
	require 'rbconfig'
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname

	libdir = basedir + "lib"
	extdir = libdir + Config::CONFIG['sitearch']

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
	$LOAD_PATH.unshift( extdir.to_s ) unless $LOAD_PATH.include?( extdir.to_s )
}


require 'rbconfig'
require 'rubygems'
require 'rake'
require 'rake/clean'

$dryrun = false

### Config constants
BASEDIR       = Pathname.new( __FILE__ ).dirname.relative_path_from( Pathname.getwd )
RAKE_TASKDIR  = BASEDIR

PKG_NAME      = 'rake-tasklibs'
PKG_SUMMARY   = ''
VERSION_FILE  = BASEDIR + 'Metarakefile'
PKG_VERSION   = VERSION_FILE.read[ /VERSION = '(\d+\.\d+\.\d+)'/, 1 ]
PKG_FILE_NAME = "#{PKG_NAME.downcase}-#{PKG_VERSION}"
GEM_FILE_NAME = "#{PKG_FILE_NAME}.gem"

DEFAULT_EDITOR  = 'vi'
COMMIT_MSG_FILE = 'commit-msg.txt'
FILE_INDENT     = " " * 12
LOG_INDENT      = " " * 3

import RAKE_TASKDIR + 'helpers.rb'
import RAKE_TASKDIR + 'hg.rb'

$trace = Rake.application.options.trace ? true : false
$dryrun = Rake.application.options.dryrun ? true : false


#####################################################################
###	T A S K S 	
#####################################################################

### Default task
task :default do
	error_message "You probably meant to run the Metarakefile."
	ask_for_confirmation( "Want me to switch over to it now?" ) do
		mrf = BASEDIR + 'Metarakefile'
		exec 'rake', '-f', mrf, *ARGV
	end
end

# Stub out the testing task, as there aren't currently any tests
task :test

