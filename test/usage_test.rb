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
def bbb(x)
  x = "D#bbb(x) : (#{x.class.name})"
  x
end
}

  multimethod %q{
def bbb(*rest)
  x = "D#bbb(*rest) : (#{rest.collect{|x| x.class}.inspect})"
  x
end
}

  multimethod %q{
def bbb(x, y)
  x = "D#bbb(x, y) : (#{x.class.name}, #{y.class.name})"
  x
end
}

  multimethod %q{
def bbb(Fixnum x, String y)
  x = "D#bbb(Fixnum x, String y) : (#{x.class.name}, #{y.class.name})"
  x
end
}

  multimethod %q{
def bbb(Fixnum x, Fixnum y = 1)
  x = "D#bbb(Fixnum x, Fixnum y = 1) : (#{x.class.name}, #{y.class.name})"
  x
end
}

  multimethod %q{
def bbb(x, String y, A a)
  x = "D#bbb(x, String y, A a) : (#{x.class.name}, #{y.class.name}, #{a.class.name})"
  x
end
}

  multimethod %q{
def bbb(Fixnum x, y, *rest)
  x = "D#bbb(Fixnum x, y, *rest) : (#{x.class.name}, #{y.class.name}, #{rest.collect{|x| x.class}.inspect})"
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

      assert_not_nil bbb_mm = ::Multimethod::Table.instance.multimethod.select{|mm| mm.name == 'bbb'}
      assert_equal 1, bbb_mm.size
      assert_kind_of ::Multimethod::Multimethod, bbb_mm = bbb_mm[0]

      assert_equal 7, bbb_mm.method.size
      
      assert_equal 'D#bbb(*rest) : ([])',
        d.bbb()

      assert_equal 'D#bbb(x) : (Symbol)',
        d.bbb(:x)

      assert_equal 'D#bbb(Fixnum x, String y) : (Fixnum, String)' ,   
        d.bbb(1, 'a')

      assert_equal 'D#bbb(Fixnum x, Fixnum y = 1) : (Fixnum, Fixnum)' ,   
        d.bbb(1, 2)

      assert_equal 'D#bbb(x, y) : (Symbol, Symbol)' ,   
        d.bbb(:x, :y)

      assert_equal 'D#bbb(*rest) : ([Symbol, D, D])' ,   
        d.bbb(:x, d, d)

      assert_equal 'D#bbb(Fixnum x, y, *rest) : (Fixnum, String, [A])' , 
        d.bbb(1, 'a', a)

      assert_equal 'D#bbb(x, String y, A a) : (String, String, A)' , 
        d.bbb('a', 'b', a)

      assert_equal 'D#bbb(Fixnum x, y, *rest) : (Fixnum, String, [Fixnum])' , 
        d.bbb(1, 'a', 3)
    end

  end # class
  
end # module
