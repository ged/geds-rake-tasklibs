# 
# Mercurial Rake Tasks
# $Id$
# 
# Authors:
# * Michael Granger <ged@FaerieMUD.org>
# 

# Mercurial constants
HG_DOTDIR = BASEDIR + '.hg'
HG_STORE  = HG_DOTDIR + 'store'

IGNORE_FILE = BASEDIR + '.hgignore'

DEFAULT_EDITOR = 'vi'
COMMIT_MSG_FILE = 'commit-msg.txt'

FILE_INDENT = " " * 12
LOG_INDENT = " " * 3


### 
### Helpers
### 

module MercurialHelpers

	### Generate a commit log from a diff and return it as a String.
	def make_commit_log
		diff = IO.read( '|-' ) or exec 'hg', 'diff'
		fail "No differences." if diff.empty?

		return diff
	end

	### Generate a changelog.
	def make_changelog
		log = IO.read( '|-' ) or exec 'hg', 'log', '--style', 'compact'
		return log
	end

	### Get the 'tip' info and return it as a Hash
	def get_tip_info
		data = IO.read( '|-' ) or exec 'hg', 'tip'
		return YAML.load( data )
	end

	### Return the ID for the current rev
	def get_current_rev
		id = IO.read( '|-' ) or exec 'hg', '-q', 'identify'
		return id
	end

	### Return the list of files which are of status 'unknown'
	def get_unknown_files
		list = IO.read( '|-' ) or exec 'hg', 'status', '-un', '--no-color'
		list = list.split( /\n/ )

		trace "New files: %p" % [ list ]
		return list
	end

	### Returns a human-scannable file list by joining and truncating the list if it's too long.
	def humanize_file_list( list, indent=FILE_INDENT )
		listtext = list[0..5].join( "\n#{indent}" )
		if list.length > 5
			listtext << " (and %d other/s)" % [ list.length - 5 ]
		end

		return listtext
	end


	### Add the list of +pathnames+ to the svn:ignore list.
	def hg_ignore_files( *pathnames )
		patterns = pathnames.flatten.collect do |path|
			'^' + Regexp.escape(path) + '$'
		end
		trace "Ignoring %d files." % [ pathnames.length ]

		IGNORE_FILE.open( File::CREAT|File::WRONLY|File::APPEND, 0644 ) do |fh|
			fh.puts( patterns )
		end
	end


	### Delete the files in the given +filelist+ after confirming with the user.
	def delete_extra_files( filelist )
		description = humanize_file_list( filelist, '  ' )
		log "Files to delete:\n ", description
		ask_for_confirmation( "Really delete them?", false ) do
			filelist.each do |f|
				rm_rf( f, :verbose => true )
			end
		end
	end

end # module MercurialHelpers


### Rakefile support
def get_vcs_rev( dir='.' )
	return MercurialHelpers.get_current_rev
end
def make_changelog
	return MercurialHelpers.make_changelog
end


###
### Tasks
###

desc "Mercurial tasks"
namespace :hg do
	include MercurialHelpers

	task :release do
		# Get the rev for the tag name
		# Look for an existing tag with that rev, and if it exists abort
		# Tag the current rev
		# Sign the current rev
		# Offer to push
	end

	task :commitlog => [COMMIT_MSG_FILE]

	task :show_commitlog do
		puts make_commit_log()
	end


	file COMMIT_MSG_FILE do
		diff = make_commit_log()

		File.open( COMMIT_MSG_FILE, File::WRONLY|File::EXCL|File::CREAT ) do |fh|
			fh.print( diff )
		end

		editor = ENV['EDITOR'] || ENV['VISUAL'] || DEFAULT_EDITOR
		system editor, COMMIT_MSG_FILE
		unless $?.success? || editor =~ /vim/i
			fail "Editor exited uncleanly."
		end
	end


	task :newfiles do
		log "Checking for new files..."

		entries = get_unknown_files()

		unless entries.empty?
			files_to_add = []
			files_to_ignore = []
			files_to_delete = []

			entries.each do |entry|
				action = prompt_with_default( "  #{entry}: (a)dd, (i)gnore, (s)kip (d)elete", 's' )
				case action
				when 'a'
					files_to_add << entry
				when 'i'
					files_to_ignore << entry
				when 'd'
					files_to_delete << entry
				end
			end

			unless files_to_add.empty?
				run 'hg', 'add', *files_to_add
			end

			unless files_to_ignore.empty?
				hg_ignore_files( *files_to_ignore )
			end

			unless files_to_delete.empty?
				delete_extra_files( files_to_delete )
			end
		end
	end
	task :add => :newfiles


	task :checkin => ['hg:newfiles', 'test', COMMIT_MSG_FILE] do
		targets = get_target_args()
		$stderr.puts '---', File.read( COMMIT_MSG_FILE ), '---'
		ask_for_confirmation( "Continue with checkin?" ) do
			run 'hg', 'ci', '-l', COMMIT_MSG_FILE, targets
			rm_f COMMIT_MSG_FILE
		end
	end
	task :commit => :checkin
	task :ci => :checkin

	CLEAN.include( COMMIT_MSG_FILE )

end

if HG_DOTDIR.exist?
	trace "Defining mercurial VCS tasks"

	desc "Check in all the changes in your current working copy"
	task :ci => 'hg:ci'
	desc "Check in all the changes in your current working copy"
	task :checkin => 'hg:ci'

	desc "Tag and sign a release"
	task :release => 'hg:release'

else
	trace "Not defining mercurial tasks: no #{HG_DOTDIR}"
end


