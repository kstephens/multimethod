require 'test_base'


class AddRemoveA < Object
end

module Multimethod

  class AddRemoveTest < TestBase

    def setup
      super

      AddRemoveA.class_eval {
  multimethod %q{
def asdfwert(x)
  x = "A#asdfwert(x) : (#{x.class.name})"
  x
end
}

  multimethod %q{
def asdfwert(AddRemoveA x)
  x = "A#asdfwert(A x) : (#{x.class.name})"
  x
end
}

      }

    end
    

    def test_find_multimethod
      assert_not_nil mm = Table.instance.find_multimethod("AddRemoveA#asdfwert(x)")
      assert 1, mm.size 
      mm = mm[0]
      assert_not_nil mm
      assert_equal 'asdfwert', mm.name

      mm
    end


    def test_remove
      # Check method counts
      assert_method_count(2)

      # Remove asdfwert(AddRemoveA x)
      assert_not_nil m = Table.instance.find_method("AddRemoveA#asdfwert(AddRemoveA x)")
      assert 1, m.size 
      m = m[0]
      assert_not_nil m
      assert_not_nil mm = m.multimethod
      assert_equal   'AddRemoveA#asdfwert(AddRemoveA x)', m.signature.to_s
      assert_equal   AddRemoveA, m.signature.mod
      assert_equal   AddRemoveA, m.signature.parameter[1].type_object

      AddRemoveA.remove_multimethod(m)
  
      assert_not_nil m = Table.instance.find_method("AddRemoveA#asdfwert(AddRemoveA x)")
      assert 0, m.size 

      assert_method_count(1)

      # Remove asdfwert(x)
      assert_not_nil m = Table.instance.find_method("AddRemoveA#asdfwert(x)")
      assert 1, m.size 
      m = m[0]
      assert_not_nil m
      assert_not_nil mm = m.multimethod
      assert_equal   'AddRemoveA#asdfwert(Kernel x)', m.signature.to_s
      assert_equal   AddRemoveA, m.signature.mod
      assert_equal   Kernel, m.signature.parameter[1].type_object

      AddRemoveA.remove_multimethod(m)

      assert_not_nil m = Table.instance.find_method("AddRemoveA#asdfwert(x)")
      assert 0, m.size 

      assert_method_count(1, 0)
    end


    def assert_method_count(impl, dispatch = 1)
      mm = test_find_multimethod

      methods = AddRemoveA.instance_methods(false).select{|x| x =~ /\d_asdfwert$/}
      assert impl, methods.size 
      assert impl, mm.method.size
      
      methods = AddRemoveA.instance_methods(false).select{|x| x = 'asdfwert'}
      assert dispatch, methods.size 
    end


  end # class
  
end # module
