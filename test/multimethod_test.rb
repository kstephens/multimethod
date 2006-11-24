require 'test_base'

module Multimethod

  class MethodTest < TestBase

    class A < Object; end
    class B < A; end
    class C < Object; end
    class D < B; end
    class E < A; end


    def setup
      super
    end
    

    def test_score
      # Make some argument lists.
      types = [ A, B, C, D, E ]
      a = { }
      c = { }
      types.each do |t1|
        n1 = t1.name.clone
        n1.sub!(/^.*::/, '')
        n1 = n1[0..0]
        types.each do |t2|
          n2 = t2.name.clone
          n2.sub!(/^.*::/, '')
          n2 = n2[0..0]
          
          symbol = "#{n1.downcase}_#{n2.downcase}".intern
          a[symbol] = [ 1, t1.new, t2.new ]
          c[symbol] = a[symbol].collect{|x| x.class}
        end
      end
                 
      rs = Parameter::RESTARG_SCORE

      assert_not_nil m1 = Method.new(:m_1, Object, :m, [ A, :x, A, :y ])
      assert_equal 3, m1.signature.min_args
      assert_equal 3, m1.signature.max_args

      assert_not_nil m2 = Method.new(:m_2, Object, :m, [ B, :x, A, :y ])
      assert_equal 3, m2.signature.min_args
      assert_equal 3, m2.signature.max_args

      assert_not_nil m3 = Method.new(:m_3, Object, :m, [ C, :x,    '*rest' ])
      assert_equal 2, m3.signature.min_args
      assert_equal nil, m3.signature.max_args
      assert_not_nil    m3.signature.restarg

      assert_not_nil m4 = Method.new(:m_4, Object, :m, [ D, :x,    :y ])
      assert_equal 3, m4.signature.min_args
      assert_equal 3, m4.signature.max_args

      assert_not_nil m5 = Method.new(:m_5, Object, :m, [ E, :y,    :y ])
      assert_equal 3, m4.signature.min_args
      assert_equal 3, m4.signature.max_args
      
      # 5 == 1.class.ancestors.index(Object)
      assert_equal [ 5, 0, 0 ]   , m1.score(c[:a_a])
      assert_equal [ 5, 0, 1 ]   , m1.score(c[:a_b])
      assert_equal nil           , m1.score(c[:a_c])
      assert_equal [ 5, 1, 1 ]   , m1.score(c[:b_b])
      assert_equal nil           , m1.score(c[:c_a])
      assert_equal [ 5, 1, 2 ]   , m1.score(c[:b_d])

      assert_equal nil           , m3.score(c[:a_a])
      assert_equal nil           , m3.score(c[:a_b])
      assert_equal nil           , m3.score(c[:b_b])
      assert_equal [ 5, 0, rs ]  , m3.score(c[:c_a])
      assert_equal [ 5, 0, rs ]  , m3.score(c[:c_c])

      # Create a multimethod for later.
      assert_not_nil mm = Multimethod.new(:test)
      mm.add_method(m1)
      mm.add_method(m2)
      mm.add_method(m3)
      mm.add_method(m4)

      # Check method lookup.
      assert_equal m1         , mm.lookup_method_(c[:a_a])
      assert_equal m2         , mm.lookup_method_(c[:b_a])
      assert_equal m2         , mm.lookup_method_(c[:b_b])

      mm
    end

  end # class
    
end # module
  
