module Multimethod

  class Method
    attr_accessor :name
    attr_accessor :signature

    attr_accessor :multimethod
    attr_accessor :file
    attr_accessor :line

    def initialize(mod, name, params)
      raise NameError, "multimethod method name not specified" unless name && name.to_s.size > 0

      name = Multimethod.normalize_name(name)

      @name = name
      @signature = Signature.new(mod, params)
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
      name ||= @name
      @signature.to_s(name)
    end


    def to_ruby
      @signature.to_ruby(@name)
    end


    def to_s_arg
      @signature.to_s_arg
    end


    def inspect
      to_s
    end
  end # class
end # module


