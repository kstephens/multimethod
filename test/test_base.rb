require 'test/unit'
require 'multimethod'

module Multimethod

  class TestBase < Test::Unit::TestCase
    def setup
      super
    end
    
    # Avoid "No test were specified" error.
    def test_foo
      assert true
    end
    
    def test_normalize_name
      assert_equal :foo              , norm(:foo)
      assert_equal :foo__bar         , norm('foo_bar')
      assert_equal :foo__bar__baz    , norm('foo_bar_baz')
      assert_equal :foo_ADD_         , norm('foo+')
      assert_equal :foo_ADD__ADD_    , norm('foo++')
      assert_equal :foo_EQ__EQ_      , norm('foo==')
    end

    def norm(x)
      Multimethod.normalize_name(x)
    end

    # Helpers.
    def assert_equal_float(x, y, eps = 1.0e-8)
      d = (x * eps).abs
      assert (x - d) <= y
      assert y <= (x + d)
    end
    

  end # class

end # module
