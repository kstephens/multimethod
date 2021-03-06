# Rakefile for ruby-multimethods      -*- ruby -*-
# Adapted from RubyGems/Rakefile

# For release
"
svn status
rake update_version
rake package
rake release VERSION=x.x.x
rake svn_release
rake publish_docs
rake announce
"

#################################################################

require 'rubygems'
require 'hoe'

PKG_Name = 'Multimethod'
PKG_DESCRIPTION = %{Supports Multimethod dispatching.

For more details, see:

http://multimethod.rubyforge.org/files/lib/multimethod_rb.html 
http://multimethod.rubyforge.org/files/README.txt
http://multimethod.rubyforge.org/

}


#################################################################
# Release notes
#

def get_release_notes(relfile = "Releases.txt")

  release = nil
  notes = [ ]

  File.open(relfile) do |f|
    while ! f.eof? && line = f.readline
      if md = /^=+ Release ([\d\.]+)/i.match(line)
        release = md[1]
        notes << line
        break
      end
    end

    while ! f.eof? && line = f.readline
      if md = /^=+ Release ([\d\.]+)/i.match(line)
        break
      end
      notes << line
    end
  end

  # $stderr.puts "Release #{release.inspect}"
  [ release, notes.join('') ]
end

#################################################################

PKG_NAME = PKG_Name.gsub(/[a-z][A-Z]/) {|x| "#{x[0,1]}_#{x[1,1]}"}.downcase

PKG_SVN_ROOT="svn+ssh://rubyforge.org/var/svn/#{PKG_NAME}/#{PKG_NAME}"

release, release_notes = get_release_notes

hoe = Hoe.new(PKG_NAME, release) do |p|
  p.author = 'Kurt Stephens'
  p.description = PKG_DESCRIPTION
  p.email = "ruby-#{PKG_NAME}@umleta.com"
  p.summary = p.description
  p.changes = release_notes
  p.url = "http://rubyforge.org/projects/#{PKG_NAME}"
  
  p.test_globs = ['test/**/*.rb']
end

PKG_VERSION = hoe.version

#################################################################
# Version file
#

def announce(msg='')
  STDERR.puts msg
end

version_rb = "lib/#{PKG_NAME}/#{PKG_NAME}_version.rb"

task :update_version do
  announce "Updating #{PKG_Name} version to #{PKG_VERSION}: #{version_rb}"
  open(version_rb, "w") do |f|
    f.puts "module #{PKG_Name}"
    f.puts "# DO NOT EDIT"
    f.puts "# This file is auto-generated by build scripts."
    f.puts "# See:  rake update_version"
    f.puts "  #{PKG_Name}Version = '#{PKG_VERSION}'"
    f.puts "end"
  end
  if ENV['RELTEST']
    announce "Release Task Testing, skipping commiting of new version"
  else
    sh %{svn commit -m "Updated to version #{PKG_VERSION}" #{version_rb} Rakefile}
  end
end

# task package => :update_version

#################################################################
# SVN
#

task :svn_release do
  sh %{svn cp -m 'Release #{PKG_VERSION}' . #{PKG_SVN_ROOT}/release/#{PKG_VERSION}}
end


# Misc Tasks ---------------------------------------------------------

def egrep(pattern)
  Dir['**/*.rb'].each do |fn|
    count = 0
    open(fn) do |f|
      while line = f.gets
	count += 1
	if line =~ pattern
	  puts "#{fn}:#{count}:#{line}"
	end
      end
    end
  end
end

desc "Look for TODO and FIXME tags in the code"
task :todo do
  egrep /#.*(FIXME|TODO|TBD)/
end

desc "Look for Debugging print lines"
task :dbg do
  egrep /\bDBG|\bbreakpoint\b/
end

desc "List all ruby files"
task :rubyfiles do 
  puts Dir['**/*.rb'].reject { |fn| fn =~ /^pkg/ }
  puts Dir['bin/*'].reject { |fn| fn =~ /CVS|.svn|(~$)|(\.rb$)/ }
end

task :make_manifest do 
  open("Manifest.txt", "w") do |f|
    f.puts Dir['**/*'].reject { |fn| ! test(?f, fn) || fn =~ /CVS|.svn|(~$)|(.gem$)|(^pkg\/)|(^doc\/)/ }.sort.join("\n") + "\n"
  end
end


