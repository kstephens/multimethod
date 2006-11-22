require 'test_base'

module Multimethod

  class MethodTest < TestBase

    class A < Object; end
    class B < A; end
    class C < Object; end
    class D < B; end

    def setup
      super
    end
    

    def test_basic
      true
    end

  end # class
    
end # module
  
