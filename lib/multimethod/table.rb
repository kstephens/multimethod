module Multimethod
  # Represents a Multimethod repository.
  #
  # There is typically only one instance.
  #
  # It provides the interface to the core extensions.
  #
  class Table

    @@instance = nil
    # Returns the current instance or creates a new one.
    def self.instance
      # THREAD CRITICAL BEGIN
      @@instance ||= self.new
      # TRREAD CRITICAL END
    end


    # A list of all Multimethod objects.
    attr_accessor :multimethod

    # Enable debugging info.
    attr_accessor :debug

    # Creates a new Table object.
    def initialize(*opts)
      @multimethod_by_name = { }
      @multimethod = [ ]

      # Type name lookup cache
      @name_to_object = { }
    end


    # Installs a new Multimethod Method using the multimethod syntax:
    #
    #    class A
    #      multimethod q{
    #        def foo(x)
    #          ...
    #        end
    #      }
    #      multimethod q{
    #        def foo(A x)
    #        end
    #      }
    #    end
    #
    # Interface to Multimethod::Module mixin multimethod
    def install_method(mod, body, file = nil, line = nil)
      file ||= __FILE__
      line ||= __LINE__
      verbose = nil
      #if body =~ /def bar\(x, y\)/
      #  verbose = 1
      #end

      # Parse the signature from the method body
      signature = Signature.new
      signature.mod = mod
      signature.verbose = verbose
      signature.file = file
      signature.line = line
      new_body = signature.scan_string(body.clone)
      
      # Get our Multimethod for this
      mm = lookup_multimethod(signature.name)
      mm.install_dispatch(mod)
      m = mm.new_method_from_signature(signature)

      # Replace the multimethod signature with a plain Ruby signature.
      new_body = m.to_ruby_def + new_body

      #if true || m.signature.restarg
      #   $stderr.puts "install_method(#{mod}) => #{m.to_ruby_signature}:\n#{new_body}"
      #end

      # Evaluate the new method body.     
      mod.module_eval(new_body, file, line)
    end


    # Returns the Multimethods that matches a signature.
    # The signature can be a String, Method or Signature object.
    def find_multimethod(x)
      case x
      when String
        signature = Signature.new(:string => x)
      when Method
        signature = x.signature
      when Signature
        signature = x
      end

      x = @multimethod.select{|mm| mm.matches_signature(signature)}

      x
    end


    # Returns a list of all the Methods that match a signature.
    #
    # The signature can be a String, Method or Signature object.
    def find_method(x)
      case x
      when String
        signature = Signature.new(:string => x)
      when Method
        signature = x.signature
      when Signature
        signature = x
      end

      x = @multimethod.select{|mm| mm.matches_signature(signature)}
      # $stderr.puts "find_method(#{x}) => #{x.inspect}"
      x = x.collect{|mm| mm.find_method(signature)}.flatten

      # $stderr.puts "find_method(#{x}) => #{x.inspect}"
      x
    end


    # Removed the Method that match a signature.
    #
    # The signature can be a String, Method or Signature object.
    #
    # Raises an error if more than one Method is found.
    def remove_method(signature)
      x = find_method(signature)
      raise("Found #{x.size} multimethods: #{x.inspect}") if x.size > 1
      x = x[0]
      x.multimethod.remove_method(x)
    end


    # Returns a Multimethod object for a method name.
    #
    # Will create a new Multimethod if needed.
    def lookup_multimethod(name)
      name = name.to_s

      # THREAD CRITICAL BEGIN
      unless mm = @multimethod_by_name[name]
        mm = Multimethod.new(name)
        mm.table = self
        @multimethod_by_name[name] = mm
        @multimethod << mm
      end
      # THREAD CRITICAL END

      mm
    end


    # Dispatches to the appropriate Method based on name, receiver and arguments.
    def dispatch(name, rcvr, args)
      unless mm = @multimethod_by_name[name]
        raise NameError, 'No method for multmethod #{name}' unless mm
      end
      mm.dispatch(rcvr, args)
    end


    #################################################
    # Support
    #

    # Returns the object for name, using the appropriate evaluation scope.
    def name_to_object(name, scope = nil, file = nil, line = nil)
      scope ||= Kernel
      # THREAD CRITICAL BEGIN
      unless x = (@name_to_object[scope] ||= { })[name]
        # $stderr.puts " name_to_object(#{name.inspect}) in #{scope}"
        x = 
          @name_to_object[scope][name] = 
          scope.module_eval(name, file || __FILE__, line || __LINE__)
      end
      # THREAD CRITICAL END

      x
    end

  end # class

end # module


