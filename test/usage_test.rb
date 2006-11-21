require 'test_base'


class A < Object
  multimethod %q{
def foo(x)
  x = "A#foo(x) : (#{x.class.name})"
  x
end
}

  multimethod %q{
def foo(A x)
  x = "A#foo(A x) : (#{x.class.name})"
  x
end
}

  multimethod %q{
def foo(B x)
  x = "A#foo(B x) : (#{x.class.name})"
  x
end
}

end

class B < A
  multimethod %q{
def foo(B x)
  x = "B#foo(B x) : (#{x.class.name})"
  x
end
}

  multimethod %q{
def foo(Comparable x)
  x = "B#foo(Comparable x) : (#{x.class.name})"
  x
end
}


end

class C < Object
  include Comparable
end

class D < B
  # Variadic
  multimethod %q{
def bar(x)
  x = "D#bar(x) : (#{x.class.name})"
  x
end
}

  multimethod %q{
def bar(*rest)
  x = "D#bar(*rest) : (#{rest.inspect})"
  x
end
}

  multimethod %q{
def bar(x, y)
  x = "D#bar(x, y) : (#{x.class.name}, #{y.class.name})"
  x
end
}

  multimethod %q{
def bar(x, y, A a)
  x = "D#bar(x, y, A a) : (#{x.class.name}, #{y.class.name}, #{a.class.name})"
  x
end
}

  multimethod %q{
def bar(x, y, *rest)
  x = "D#bar(x, y, *rest) : (#{x.class.name}, #{y.class.name}, #{rest.inspect})"
  x
end
}

end # class D

class E < A
end


module Multimethod

  class UsageTest < TestBase

    def setup
      super
    end
    
    def test_call
      a = A.new
      b = B.new
      c = C.new
      d = D.new
      e = E.new

      assert_equal 'A#foo(x) : (Fixnum)' , a.foo(1)
      assert_equal 'A#foo(A x) : (A)'    , a.foo(a)
      assert_equal 'A#foo(B x) : (B)'    , a.foo(b)
      assert_equal 'A#foo(x) : (C)'      , a.foo(c)
      assert_equal 'A#foo(B x) : (D)'    , a.foo(d)
      assert_equal 'A#foo(A x) : (E)'    , a.foo(e)

      assert_equal 'A#foo(x) : (Symbol)' , b.foo(:x)
      assert_equal 'B#foo(Comparable x) : (Fixnum)' , b.foo(1)
      assert_equal 'A#foo(A x) : (A)'    , b.foo(a)
      assert_equal 'B#foo(B x) : (B)'    , b.foo(b)
      assert_equal 'B#foo(Comparable x) : (C)'      , b.foo(c)
      assert_equal 'B#foo(B x) : (D)'    , b.foo(d)
      assert_equal 'A#foo(A x) : (E)'    , b.foo(e)
    end

    def test_variadic
      a = A.new
      d = D.new

      assert_equal 'D#bar(*rest) : ([])',
        d.bar()

      assert_equal 'D#bar(x) : (Fixnum)',
        d.bar(1)

      assert_equal 'D#bar(x, y) : (Fixnum, String)' ,   
        d.bar(1, 'a')

      assert_equal 'D#bar(x, y, A a) : (Fixnum, String, A)' , 
        d.bar(1, 'a', a)

      assert_equal 'D#bar(x, y, *rest) : (Fixnum, String, [3])' , 
        d.bar(1, 'a', 3)
    end

  end # class
  
end # module
