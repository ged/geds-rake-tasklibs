# 
# RDoc Rake tasks
# $Id$
# 

require 'rdoc/rdoc'
require 'rake/clean'


if RDoc::RDoc::GENERATORS.key?( 'darkfish' )
	$have_darkfish = true
else
	trace "No darkfish generator."
	$have_darkfish = false
end


# Append docs/lib to the load path if it exists for a locally-installed Darkfish
DOCSLIB = DOCSDIR + 'lib'
$LOAD_PATH.unshift( DOCSLIB.to_s ) if DOCSLIB.exist?

# Make relative string paths of all the stuff we need to generate docs for
DOCFILES = LIB_FILES + EXT_FILES + GEMSPEC.extra_rdoc_files


directory RDOCDIR.to_s
CLOBBER.include( RDOCDIR )

desc "Build API documentation in #{RDOCDIR}"
task :rdoc => [ Rake.application.rakefile, *DOCFILES ] do
	args = RDOC_OPTIONS 
	args += [ '-o', RDOCDIR.to_s ]
	args += [ '-f', 'darkfish' ] if $have_darkfish
	args += DOCFILES.collect {|pn| pn.to_s }

	trace "Building docs with arguments: %s" % [ args.join(' ') ]
	RDoc::RDoc.new.document( args ) rescue nil
end

desc "Rebuild API documentation in #{RDOCDIR}"
task :rerdoc do
	rm_r( RDOCDIR ) if RDOCDIR.exist?
	Rake::Task[ :rdoc ].invoke
end

