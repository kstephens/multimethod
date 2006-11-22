require 'test_base'

module Multimethod

  class SignatureTest < TestBase

    class A < Object; end
    class B < A; end
    class C < Object; end
    class D < B; end


    def setup
      super
    end
    

    def test_scan_parameter
      assert_not_nil m1 = Signature.new(:mod => Object, 
                                        :name => :m, 
                                        :parameter => [ A, :a, B, :b, :c, '*d' ])

      assert_equal 5, m1.parameter.size

      i = -1
      
      i = i + 1
      assert_equal :self,  m1.parameter[i].name
      assert_equal Object, m1.parameter[i].type
      assert       !       m1.parameter[i].restarg

      i = i + 1
      assert_equal :a, m1.parameter[i].name
      assert_equal A, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg

      i = i + 1
      assert_equal :b, m1.parameter[i].name
      assert_equal B, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg

      i = i + 1
      assert_equal :c, m1.parameter[i].name
      assert_equal Kernel, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg

      i = i + 1
      assert_equal :d, m1.parameter[i].name
      assert_equal Kernel, m1.parameter[i].type
      assert       m1.parameter[i].restarg

      m1
    end


    def assert_signature(m1)
      assert_equal 5, m1.parameter.size
      
      i = -1

      i = i + 1
      assert_equal :self, m1.parameter[i].name
      assert_equal Object, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg

      i = i + 1
      assert_equal :a, m1.parameter[i].name
      assert_equal 'A', m1.parameter[i].type
      assert       !  m1.parameter[i].restarg

      i = i + 1
      assert_equal :b, m1.parameter[i].name
      assert_equal 'B', m1.parameter[i].type
      assert       !  m1.parameter[i].restarg

      i = i + 1
      assert_equal :c, m1.parameter[i].name
      assert_equal Kernel, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg

      i = i + 1
      assert_equal :d, m1.parameter[i].name
      assert_equal Kernel, m1.parameter[i].type
      assert       m1.parameter[i].restarg

      m1
    end


    def test_scan_parameter_string
      assert_not_nil m1 = Signature.new(:mod => Object, :name => :m, :parameter => 'A a, B b, c = nil, *d')
      assert_signature m1
    end


    def test_scan_string
      assert_not_nil m1 = Signature.new(:string => 'Object#m(A a, B b, c = nil, *d)')

      # FIXME!
      if m1.mod == 'Object'
        m1.mod = Object 
      end
      if m1.parameter[0].type == 'Object'
        m1.parameter[0].type = Object 
      end

      assert_signature m1
    end


  end # class
    
end # module
  
