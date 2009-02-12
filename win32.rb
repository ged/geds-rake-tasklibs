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

NEW_ALT_SEPARATOR = '"\\\\\" ' + ?\

CONFIGURE_CMD = %w[
	env
		ac_cv_func_getpgrp_void=no
		ac_cv_func_setpgrp_void=yes
		rb_cv_negative_time_t=no
		ac_cv_func_memcmp_working=yes
		rb_cv_binary_elf=no
    ./configure
	    --host=i386-mingw32
	    --target=i386-mingw32
	    --build=#{RUBY_PLATFORM}
	    --prefix=#{XCOMPILER_DIR}
]

begin
	require 'archive/tar'
	
	namespace :win32 do
		directory XCOMPILER_DIR
		
		file XCOMPILER_DL => XCOMPILER_DIR do
			download RUBY_DL_URI, XCOMPILER_DL
		end

		directory XCOMPILER_SRC
		task XCOMPILER_SRC => [ XCOMPILER_DIR, XCOMPILER_DL ] do
			Archive::Tar.extract( XCOMPILER_DL, XCOMPILER_DIR, :compression => :gzip ) or
				fail "Extraction of %s failed." % [ XCOMPILER_DL ]
		end

		file XCOMPILER_RUBY => XCOMPILER_SRC do
			Dir.chdir( XCOMPILER_SRC ) do
				File.open( 'Makefile.in.new', IO::CREAT|IO::WRONLY|IO::EXCL ) do |ofh|
					File.each_line( 'Makefile.in' ) do |line|
						line.sub!( /ALT_SEPARATOR = "\\\\"/, NEW_ALT_SEPARATOR )
						ofh.write( line )
					end
				end

				mv 'Makefile.in.new', 'Makefile.in'
				
				run *CONFIGURE_CMD
			end
		end

		task :build => XCOMPILER_RUBY do
			log "Building..."
		end
	end

rescue LoadError => err
	task :no_win32_build do
		fatal "No win32 build: %s: %s" % [ err.class.name, err.message ]
	end
	
	namespace :win32 do
		task :build => :no_win32_build
	end
			
end

