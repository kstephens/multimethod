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


    def test_parse
      p2 = parse_parameter("Kernel y = nil")
      assert_equal 'Kernel', p2.type
      assert_equal :y, p2.name
      assert_equal 'nil', p2.default
      assert       ! p2.restarg

      p2
    end


    def test_equal
      p1 = parse_parameter("x")
      p2 = parse_parameter("x")
      assert p1 == p2

      p1 = parse_parameter("x")
      p2 = parse_parameter("y")
      assert p1 == p2

      p1 = parse_parameter("x")
      assert_equal Kernel, p1.type_object
      p2 = parse_parameter("Kernel y")
      assert_equal Kernel, p2.type_object
      assert p1 == p2

      p1 = parse_parameter("Kernel x")
      p2 = parse_parameter("Kernel y")
      assert p1 == p2

      p1 = parse_parameter("Kernel x")
      assert_equal nil, p1.default
      p2 = parse_parameter("Kernel y = nil")
      assert_equal 'nil', p2.default
      assert p1 != p2

    end


    def parse_parameter(x)
      p1 = Parameter.new
      # p1.verbose = 1
      x = p1.scan_string(x)
      assert_equal 0, x.size
      p1
    end

  end # class
  
end # module
