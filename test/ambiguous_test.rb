require 'test_base'


class Amb < Object

  multimethod %q{
def amb(x = nil)
  x = "Amb#amb(x = nil) : (#{x.class.name})"
  x
end
}

  multimethod %q{
def amb(Amb x = nil)
  x = "Amb#amb(Amb x = nil) : (#{x.class.name})"
  x
end
}

end


module Multimethod

  class AmbiguousTest < TestBase

    def setup
      super
    end
    
    def test_call
      assert_not_nil mm = Table.instance.lookup_multimethod(:amb)
      # mm.debug = 1

      a = Amb.new
      assert_equal "Amb#amb(x = nil) : (Fixnum)", a.amb(1)
      assert_equal "Amb#amb(Amb x = nil) : (Amb)", a.amb(a)
      assert_raise(NameError) { a.amb() }

      # mm.debug = nil
    end


  end # class
  
end # module
