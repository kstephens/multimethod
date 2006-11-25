module Multimethod

  # Represents a Method implementation in a Multimethod.
  #
  # A Method is bound to a Module using a unique implementation name for the Multimethod.
  #
  # A Multimethod may have multiple implementation Methods.
  #
  # The Multimethod is responsible for determining the correct Method based on the
  # relative scoring of the Method Signature.
  #
  class Method
    # The Method's Signature used for relative scoring of applicability to an argument list.
    attr_accessor :signature
    
    # The Method's underlying method name.
    # This method name is unique.
    attr_accessor :impl_name

    # The Method's Multimethod.
    attr_accessor :multimethod

    # Initialize a new Method.
    # 
    #   Method.new(impl_name, signature)
    #   Method.new(impl_name, mod, name, parameter_list)
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
    

    # Returns true if this Method matches the Signature.
    def matches_signature(signature)
      @signature == signature
    end


    # Remove the method implementation from the receiver Module.
    def remove_implementation
      # $stderr.puts "Removing implementation for #{signature.to_s} => #{impl_name}"
      signature.mod.class_eval("remove_method #{impl_name.inspect}")
    end


    # Returns 0.
    def <=>(x)
      0
    end


    # Parameters
    def parameter
      @signature.parameter
    end


    # Score of this Method based on the argument types.
    # The receiver type is the first element of args.
    def score(args)
      @signature.score(args)
    end


    # Score this Method based on the argument types
    # using a cache.
    def score_cached(args)
      @signature.score_cached(args)
    end


    # Returns a string representation using the 
    # implementation name.
    def to_s(name = nil)
      name ||= @impl_name
      @signature.to_s(name)
    end


    # Returns the "def foo(...)" string
    # using the implementation name by default.
    def to_ruby_def(name = nil)
      name ||= @impl_name
      @signature.to_ruby_def(name)
    end


    # Returns a ruby signature
    # using the implementation name by default.
    def to_ruby_signature(name = nil)
      name ||= @impl_name
      @signature.to_ruby_signature(name)
    end


    # Returns a string representing the Ruby parameters.
    def to_ruby_arg
      @signature.to_ruby_arg
    end

    # Same as #to_s.
    def inspect
      to_s
    end
  end # class
end # module


