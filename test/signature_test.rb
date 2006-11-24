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
      assert       !       m1.parameter[i].default

      i = i + 1
      assert_equal :a, m1.parameter[i].name
      assert_equal A, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg
      assert       !       m1.parameter[i].default

      i = i + 1
      assert_equal :b, m1.parameter[i].name
      assert_equal B, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg
      assert       !       m1.parameter[i].default

      i = i + 1
      assert_equal :c, m1.parameter[i].name
      assert_equal Kernel, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg
      assert       !       m1.parameter[i].default

      i = i + 1
      assert_equal :d, m1.parameter[i].name
      assert_equal Kernel, m1.parameter[i].type
      assert       m1.parameter[i].restarg
      assert       !       m1.parameter[i].default

      m1
    end


    def assert_signature(m1)
      assert_equal 5, m1.parameter.size
      
      i = -1

      i = i + 1
      assert_equal :self, m1.parameter[i].name
      assert_equal Object, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg
      assert       !       m1.parameter[i].default

      i = i + 1
      assert_equal :a, m1.parameter[i].name
      assert_equal 'A', m1.parameter[i].type
      assert       !  m1.parameter[i].restarg
      assert       !       m1.parameter[i].default

      i = i + 1
      assert_equal :b, m1.parameter[i].name
      assert_equal 'B', m1.parameter[i].type
      assert       !  m1.parameter[i].restarg

      i = i + 1
      assert_equal :c, m1.parameter[i].name
      assert_equal Kernel, m1.parameter[i].type
      assert       !  m1.parameter[i].restarg
      assert_equal 'nil', m1.parameter[i].default

      i = i + 1
      assert_equal :d, m1.parameter[i].name
      assert_equal Kernel, m1.parameter[i].type
      assert       m1.parameter[i].restarg
      assert       !       m1.parameter[i].default

      m1
    end


    def test_scan_parameter_string
      assert_not_nil m1 = Signature.new(:mod => Object, :name => :m, :parameter => 'A a, B b, c = nil, *d')
      assert_signature m1
      assert ! m1.class_method
    end


    def test_scan_string
      assert_not_nil m1 = Signature.new(:string => 'Object#m(A a, B b, c = nil, *d)')

      assert_signature m1
      assert ! m1.class_method
    end


    def test_scan_string_2
      assert_not_nil m1 = Signature.new(:string => 'Object def m(A a, B b, c = nil, *d)')

      assert_signature m1
      assert ! m1.class_method
    end


    def test_scan_string_class_method
      assert_not_nil m1 = Signature.new(:string => 'Object.m(A a, B b, c = nil, *d)')

      assert_signature m1
      assert m1.class_method
    end


    def test_scan_string_class_method_2
      assert_not_nil m1 = Signature.new(:string => 'Object def self.m(A a, B b, c = nil, *d)')

      assert_signature m1
      assert m1.class_method
    end


    def test_scan_string_balanced_parens
      assert_not_nil m1 = Signature.new(:string => 'Object.m(A a, B b = call_method(foo(bar, "45,67"), \',\'), c = nil, *d)')

      assert_signature m1
      assert           m1.class_method
      assert_equal     :b, m1.parameter[2].name
      assert           m1.parameter[2].default
      assert_equal     'call_method(foo(bar, "45,67"), \',\')', m1.parameter[2].default
    end

    def test_scan_default_at_end
      assert_not_nil m1 = Signature.new(:string => 'Object.m(A a, B b = call_method(foo(bar, "45,67"), \',\'), c = nil)')

      assert           m1.class_method
      assert_equal     :c, m1.parameter[3].name
      assert           m1.parameter[3].default
      assert_equal     'nil', m1.parameter[3].default
    end


    def test_cmp
      assert_not_nil m1 = Signature.new(:string => 'Object#m(A a, B b, c = nil, *d)')
      assert_not_nil m2 = Signature.new(:string => 'Object#m(A a, B b, c = nil, *d)')

      assert_equal 0, m1 <=> m2


      assert_not_nil m1 = Signature.new(:string => 'Object#m(A a, B b, c = nil, *d)')
      assert_not_nil m2 = Signature.new(:string => 'Object#m(A q, B x, c = nil, *args)')

      assert_equal 0, m1 <=> m2

      assert_not_nil m1 = Signature.new(:string => 'Object#m(A a, B b, c = nil, *d)')
      assert_not_nil m2 = Signature.new(:string => 'Object#m(A q, B x, c = nil, d)')

      assert_equal 1, m1 <=> m2

      assert_not_nil m1 = Signature.new(:string => 'Object#m(A a, B b, c = nil, *d)')
      assert_not_nil m2 = Signature.new(:string => 'Object#m(A q, B x, c = nil)')

      assert_equal 1, m1 <=> m2
     end

  end # class
    
end # module
  
