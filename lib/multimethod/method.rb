module Multimethod

  class Method
    attr_accessor :signature
    attr_accessor :impl_name

    attr_accessor :multimethod
    attr_accessor :file
    attr_accessor :line

    def initialize(impl_name, *args)
      if args.size == 1
        @signature = args[0]
      else
        mod, name, params = *args
        raise NameError, "multimethod method name not specified" unless name && name.to_s.size > 0
        raise NameError, "multimethod method impl_name not specified" unless impl_name && impl_name.to_s.size > 0
        
        @signature = Signature.new(:mod => mod, :name => name, :parameter => params)
      end

      impl_name = Multimethod.normalize_name(impl_name)

      @impl_name = impl_name
    end
    

    def multimethod=(x)
      @multimethod = x
      @signature && @signature.multimethod = x
    end


    def matches_signature(signature)
      @signature == signature
    end


    def remove_implementation
      # Remove the method implementation
      # $stderr.puts "Removing implementation for #{signature.to_s} => #{impl_name}"
      signature.mod.class_eval("remove_method #{impl_name.inspect}")
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


