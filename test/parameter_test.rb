require 'test_base'

module Multimethod

  class ParameterTest < TestBase

    class A < Object; end
    class B < A; end
    class C < Object; end
    class D < B; end

    def setup
      super
    end
    
    def test_score
      pA = Parameter.new(:a, A)
      assert_equal 0,   pA.score(A)
      assert_equal 1,   pA.score(B)
      assert_equal nil, pA.score(C)
      assert_equal 2,   pA.score(D)

      pB = Parameter.new(:b, B)
      assert_equal nil, pB.score(A)
      assert_equal 0,   pB.score(B)
      assert_equal nil, pB.score(C)
      assert_equal 1,   pB.score(D)
    end
  end # class
  
end # module
