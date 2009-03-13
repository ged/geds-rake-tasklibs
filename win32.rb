# 
# Win32-specific tasks (cross-compiling, etc.)
# 
# Thanks to some people that understand this stuff better than me for
# posting helpful blog posts. This stuff is an amalgam of stuff they did:
# 
# * Mauricio Fernandez
#   http://eigenclass.org/hiki/cross+compiling+rcovrt
# 
# * Jeremy Hinegardner
#   http://www.copiousfreetime.org/articles/2008/10/12/building-gems-for-windows.html
# 
# * Aaron Patterson
#   http://tenderlovemaking.com/2008/11/21/cross-compiling-ruby-gems-for-win32/

require 'rake'
require 'pathname'
require 'rbconfig'

HOMEDIR        = Pathname( '~' ).expand_path
RUBYVERSION    = '1.8.6-p287'
RUBY_DL_BASE   = 'ftp://ftp.ruby-lang.org/pub/ruby/1.8/'
RUBY_DL_URI    = RUBY_DL_BASE + "ruby-#{RUBYVERSION}.tar.gz"

XCOMPILER_DIR  = HOMEDIR + '.ruby_mingw32'

XCOMPILER_DL   = XCOMPILER_DIR + "ruby-#{RUBYVERSION}.tar.gz"
XCOMPILER_SRC  = XCOMPILER_DIR + "ruby-#{RUBYVERSION}"

XCOMPILER_BIN  = XCOMPILER_DIR + 'bin'
XCOMPILER_RUBY = XCOMPILER_BIN + 'ruby.exe'

TAR_OPTS = { :compression => :gzip }

CONFIGURE_CMD = %W[
	env
		ac_cv_func_getpgrp_void=no
		ac_cv_func_setpgrp_void=yes
		rb_cv_negative_time_t=no
		ac_cv_func_memcmp_working=yes
		rb_cv_binary_elf=no
    ./configure
	    --host=i386-mingw32
	    --target=i386-mingw32
	    --build=#{Config::CONFIG['host']}
	    --prefix=#{XCOMPILER_DIR}
]

### Archive::Tar::Reader#extract (as of 0.9.0) is broken w.r.t.
### permissions, so we have to do this ourselves.
def untar( tarfile, targetdir )
	targetdir = Pathname( targetdir )
	raise "No such directory: #{targetdir}" unless targetdir.directory?

	reader = Archive::Tar::Reader.new( tarfile.to_s, TAR_OPTS )
	
	mkdir_p( targetdir )
	reader.each( true ) do |header, body|
		path = targetdir + header[:path]
		# trace "Header is: %p" % [ header ]

		case header[:type]
		when :file
			trace "  #{path}"
			path.open( File::WRONLY|File::EXCL|File::CREAT|File::TRUNC, header[:mode] ) do |fio|
				bytesize = header[:size]
				fio.write( body[0,bytesize] )
			end

		when :directory
			trace "  #{path}"
			path.mkpath
			
		when :link
			linktarget = targetdir + header[:dest]
			trace "  #{path} => #{linktarget}"
			path.make_link( linktarget.to_s )

		when :symlink
			linktarget = targetdir + header[:dest]
			trace "  #{path} -> #{linktarget}" 
			path.make_symlink( linktarget )
		end
	end
	
end


begin
	require 'archive/tar'
	
	namespace :win32 do
		directory XCOMPILER_DIR.to_s
		
		file XCOMPILER_DL => XCOMPILER_DIR do
			# openuri can't handle this -- passive ftp required?
			run 'wget', '-O', XCOMPILER_DL, RUBY_DL_URI
		end

		directory XCOMPILER_SRC.to_s
		task XCOMPILER_SRC => [ XCOMPILER_DIR, XCOMPILER_DL ] do
			if XCOMPILER_SRC.exist?
				trace "Rake fails. #{XCOMPILER_SRC} already exists."
			else
				untar( XCOMPILER_DL, XCOMPILER_DIR )
			end
		end

		file XCOMPILER_RUBY => XCOMPILER_SRC do
			Dir.chdir( XCOMPILER_SRC ) do
				unless File.exist?( 'Makefile.in.orig' )
					File.open( 'Makefile.in.new', IO::CREAT|IO::WRONLY|IO::EXCL ) do |ofh|
						IO.readlines( 'Makefile.in' ).each do |line|
							next if line.include?( 0.chr )
							trace "  copying line: %p" % [ line ]
							line.sub!( /ALT_SEPARATOR = ".*?"/, "ALT_SEPARATOR = 92.chr" )
							ofh.write( line )
						end
					end

					mv 'Makefile.in', 'Makefile.in.orig'
					mv 'Makefile.in.new', 'Makefile.in'
				end
				
				run *CONFIGURE_CMD
				run 'make', 'ruby'
				run 'make', 'rubyw.exe'
				run 'make', '-n', 'install'
			end
		end

		desc "Build a binary Gem for Win32 systems, installing a cross " +
		     "compiled Ruby if necessary"
		task :build => XCOMPILER_RUBY do
			log "Building..."
		end
	end

rescue LoadError => err
	task :no_win32_build do
		fatal "No win32 build: %s: %s" % [ err.class.name, err.message ]
	end
	
	namespace :win32 do
		desc "Build a binary Gem for Win32 systems, installing a cross " +
		     "compiled Ruby if necessary"
		task :build => :no_win32_build
	end
			
end


