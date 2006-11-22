module Multimethod

  class Method
    attr_accessor :signature
    attr_accessor :impl_name

    attr_accessor :multimethod
    attr_accessor :file
    attr_accessor :line

    def initialize(impl_name, mod, name, params)
      raise NameError, "multimethod method name not specified" unless name && name.to_s.size > 0
      raise NameError, "multimethod method impl_name not specified" unless impl_name && impl_name.to_s.size > 0

      impl_name = Multimethod.normalize_name(impl_name)

      @impl_name = impl_name
      @signature = Signature.new(:mod => mod, :name => name, :parameter => params)
    end
    

    def multimethod=(x)
      @multimethod = x
      @signature && @signature.multimethod = x
    end


    # For score sort
    def <=>(x)
      0
    end


    # Parameters
    def parameter
      @signature.parameter
    end


    # Scoring this method.
    def score(args)
      @signature.score(args)
    end


    def score_cached(args)
      @signature.score_cached(args)
    end


    def to_s(name = nil)
      name ||= @impl_name
      @signature.to_s(name)
    end


    def to_ruby_def(name = nil)
      name ||= @impl_name
      @signature.to_ruby_def(name)
    end


    def to_ruby_signature(name = nil)
      name ||= @impl_name
      @signature.to_ruby_signature(name)
    end


    def to_ruby_arg
      @signature.to_ruby_arg
    end


    def inspect
      to_s
    end
  end # class
end # module


