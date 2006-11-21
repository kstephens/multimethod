require 'multimethod'

class A
  multimethod %q{
  def foo(x) # matches any argument type
     "#{x.inspect}"
  end
  }

  multimethod %q{
  def foo(Fixnum x) # matches any Fixnum
     "Fixnum #{x.inspect}"
  end
  }

  multimethod %q{
  def foo(Numeric x) # matches any Numeric
     "Numeric #{x.inspect}"
  end
  }
end

a = A.new
puts a.foo(:symbol) # ==> ":symbol"
puts a.foo(45)      # ==> "Fixnum 45"
puts a.foo(12.34)      # ==> "Numeric 12.34"
