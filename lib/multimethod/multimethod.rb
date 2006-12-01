module Multimethod
  # Represents a Multimethod.
  #
  # A Multimethod has multiple implementations of a method based on the relative scoring
  # of the Methods based on the argument types of the message.
  # 
  # A Multimethod has a name.
  #
  class Multimethod

    # The Multimethod's name.
    attr_accessor :name

    # A list of Method's that implement this Multimethod.
    attr_accessor :method

    # The Multimethod::Table that owns this Multimethod.
    attr_accessor :table

    # Enable debugging info.
    attr_accessor :debug

    # Initialize a new Multimethod.
    def initialize(name, *opts)
      raise NameError, "multimethod name not specified" unless name && name.to_s.size > 0
      @debug = nil

      @name = name
      @name_i = 0
      @method = [ ]
      @dispatch = { }

      @lookup_method = { }
      
    end


    # Generates a unique symbol for a method name.
    # Method implementations will use a unique name for the implementation method.
    # For example, for a Multimethod named "foo", the Method name might be "_multimethod_12_foo".
    def gensym(name = nil)
      name ||= @name
      "_multimethod_#{@name_i = @name_i + 1}_#{name}"
    end

    # Creates a new Method object bound to mod by name.
    def new_method(mod, name, *args)
      m = Method.new(gensym(name), mod, name, *args)
      add_method(m)
      m
    end

    # Create a new Method object using the Signature.
    def new_method_from_signature(signature)
      m = Method.new(gensym(name), signature)
      add_method(m)
      m
    end


    # Adds the new Method object to this Multimethod.
    def add_method(method)
      # THREAD CRITICAL BEGIN
      remove_method(method.signature)
      @method.push(method)
      method.multimethod = self
      @lookup_method = { } # flush cache
      # THREAD CRITICAL END
    end


    # Returns true if this Multimethod matches the Signature.
    def matches_signature(signature)
      @name == signature.name
    end


    # Returns a list of all Methods that match the Signature.
    def find_method(signature)
      m = @method.select{|x| x.matches_signature(signature)}

      m
    end

    # Removes the method.
    def remove_method(x)
      case x
      when Signature
        m = find_method(x) 
        m = m[0]
        return unless m
        raise("No method found for #{x.to_s}") unless m
      else
        m = x
      end

      m.remove_implementation
      m.multimethod = nil
      @method.delete(m)
      @lookup_method = { } # flush cache

      # Remove multimethod dispatch in the method's module?
      if @method.collect{|x| m.signature.mod = m.signature.mod}.empty?
        remove_dispatch(m.signature.mod)
      end
    end


    def dispatch(rcvr, args)
      apply_method(lookup_method(rcvr, args), rcvr, args)
    end


    # Interface to Multimethod::Table
    def apply_method(meth, rcvr, args)
      unless meth # && false
        $stderr.puts "Available multimethods for #{rcvr.class.name}##{@name}(#{args}):"
        $stderr.puts "  " + @method.sort{|a,b| a.min_args <=> b.min_args }.collect{|x| x.to_s(name)}.join("\n  ")
        $stderr.puts "\n"
      end
      raise NameError, "Cannot find multimethod for #{rcvr.class.name}##{@name}(#{args})" unless meth
      rcvr.send(meth.impl_name, *args)
    end


    def lookup_method(rcvr, args)
      args = args.clone
      args.unshift(rcvr)
      lookup_method_cached_(args)
    end


    def lookup_method_cached_(args)
      args_type = args.collect{|x| x.class}

      # THREAD CRITICAL BEGIN
      unless result = @lookup_method[args_type]
        result = @lookup_method[args_type] =
          lookup_method_(args_type)
      end
      # THREAD CRITICAL END

      result
    end


    def lookup_method_(args)
      scores = score_methods(@method, args)
      if scores.empty?
        result = nil
      else
        result = scores[0][1]
        raise("Ambigious method") if scores.select{|x| x[0] == result}.size > 1
      end

      #if @name.to_s == 'bar'
      #  $stderr.puts "args = " + args.collect{|x| x.class.name + ' ' + x.to_s}.join(",  ")
      #  $stderr.puts "scores:\n  " + scores.collect{|x| x.inspect}.join("\n  ")
      # end


      result
    end


    # Returns a sorted list of scores and Methods that
    # match the argument types.
    def score_methods(meths, args)
      scores = meths.collect do |meth|
        score = meth.score_cached(args)
        if score 
          score = [ score, meth ]
        else
          score = nil
        end

        score
      end

      scores.compact!
      scores.sort!
      
      $stderr.puts %{  score_methods(#{args.inspect}) => \n#{scores.collect{|x| x.inspect}.join("\n")}} if @debug

      scores
    end


    # Installs a dispatching method in the Module.
    # This method will dispatch to the Multimethod for Method lookup and application.
    def install_dispatch(mod)
      # THREAD CRITICAL BEGIN
      unless @dispatch[mod]
        @dispatch[mod] = true
        # $stderr.puts "install_dispatch(#{name}) into #{mod}\n";
        mod.class_eval(body = <<-"end_eval", __FILE__, __LINE__)
def #{name}(*args)
  ::#{table.class.name}.instance.dispatch(#{name.inspect}, self, args)
end
end_eval
# $stderr.puts "install_dispatch = #{body}"
      end
      # THREAD CRITICAL END
    end


    # Removes the dispatching method in the Module.
    def remove_dispatch(mod)
      # THREAD CRITICAL BEGIN
      if @dispatch[mod]
        @dispatch[mod] = false
        # $stderr.puts "Removing dispatch for #{mod.name}##{name}"
        mod.class_eval("remove_method #{name.inspect}")
      end
      # THREAD CRITICAL END
    end


    ##################################################
    # Support
    #

    @@name_map = {
      '@' => 'AT',
      '=' => 'EQ',
      '<' => 'LT',
      '>' => 'GT',
      '+' => 'ADD',
      '-' => 'SUB',
      '*' => 'MUL',
      '/' => 'DIV',
      '%' => 'MOD',
      '^' => 'XOR',
      '|' => 'OR',
      '&' => 'AND',
      '!' => 'NOT',
      '~' => 'TIL',
      nil => nil
    };
    @@name_map.delete(nil)

    @@name_rx = Regexp.new('(' + @@name_map.keys.collect{|x| Regexp.quote(x)}.join('|') + ')')

    def self.normalize_name(name)
      name = name.to_s.clone
      name.sub!(@@name_rx){|x| "_#{@@name_map[x] || '_'}_"}

      name.intern
    end

  end # class

end # module


