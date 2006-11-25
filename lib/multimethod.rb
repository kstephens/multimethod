# == Introduction
#
# The Multimethod package implements dispatch of messages to 
# multiple methods based on argument types.
#
# Variadic methods and default values are supported.
#
# Methods can be added and removed at run-time.
#
# == Examples
#
#  require 'multimethod'
#
#  class A
#    multimethod %q{
#    def foo(x) # matches any argument type
#       "#{x.inspect}"
#    end
#    }
#  
#    multimethod %q{
#    def foo(Fixnum x) # matches any Fixnum
#       "Fixnum #{x.inspect}"
#    end
#    }
#  
#    multimethod %q{
#    def foo(Numeric x) # matches any Numeric
#       "Numeric #{x.inspect}"
#    end
#    }
#  end
#  
#  a = A.new
#  puts a.foo(:symbol) # ==> ":symbol"
#  puts a.foo(45)      # ==> "Fixnum 45"
#  puts a.foo(12.34)   # ==> "Numeric 12.34"
#
# == Known Issues
#
# This library is not yet thread-safe, due to caching mechanisms
# used to increase performance.  This will be fixed in a future release.
#
# == Home page
#
# * {Multimethod Home}[http://multimethod.rubyforge.org]
#
# == Credits
#
# Multimethod was developed by:
#
# * Kurt Stephens -- ruby-multimethod(at)umleta.com, sponsored by umleta.com
#
# == Contributors
#
# Maybe you?
#
# == See Also
#
# * http://en.wikipedia.org/wiki/Multimethod
# * http://rubyforge.org/projects/multi/
#
module Multimethod
end

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'multimethod/table'
require 'multimethod/multimethod'
require 'multimethod/method'
require 'multimethod/signature'
require 'multimethod/parameter'
require 'multimethod/core_extensions'

