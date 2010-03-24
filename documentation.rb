# 
# Documentation Rake tasks
# 

require 'rake/clean'


# Append docs/lib to the load path if it exists for documentation
# helpers.
DOCSLIB = DOCSDIR + 'lib'
$LOAD_PATH.unshift( DOCSLIB.to_s ) if DOCSLIB.exist?

# Make relative string paths of all the stuff we need to generate docs for
DOCFILES = Rake::FileList[ LIB_FILES + EXT_FILES + GEMSPEC.extra_rdoc_files ]


# Prefer YARD, fallback to RDoc
begin
	require 'yard'
	require 'yard/rake/yardoc_task'

	# Undo the lazy-assed monkeypatch yard/globals.rb installs and
	# re-install them as mixins as they should have been from the
	# start
	# <metamonkeypatch>
	class Object
		remove_method :log
		remove_method :P
	end

	module YardGlobals
		def P(namespace, name = nil)
			namespace, name = nil, namespace if name.nil?
			YARD::Registry.resolve(namespace, name, false, true)
		end

		def log
			YARD::Logger.instance
		end
	end

	class YARD::CLI::Base; include YardGlobals; end
	class YARD::Parser::SourceParser; extend YardGlobals; include YardGlobals; end
	class YARD::Parser::CParser; include YardGlobals; end
	class YARD::CodeObjects::Base; include YardGlobals; end
	class YARD::Handlers::Base; include YardGlobals; end
	class YARD::Serializers::Base; include YardGlobals; end
	module YARD::Templates::Helpers::ModuleHelper; include YardGlobals; end
	# </metamonkeypatch>

	YARD_OPTIONS = [] unless defined?( YARD_OPTIONS )

	YARD::Rake::YardocTask.new( :apidocs ) do |task|
		task.files   = DOCFILES
		task.options = YARD_OPTIONS
	end
rescue LoadError
	require 'rdoc/task'

	desc "Build API documentation in #{DOCDIR}"
	RDoc::Task.new( :apidocs ) do |task|
		task.main     = "README"
		task.rdoc_files.include( DOCFILES )
		task.rdoc_dir = API_DOCSDIR
		task.options  = RDOC_OPTIONS
	end
end

# Need the DOCFILES to exist to build the API docs
task :apidocs => DOCFILES
