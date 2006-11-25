module Multimethod

  # Represents a method signature.
  # 
  # A Signature has a bound Module, a name and a Parameter list.
  #
  # Each Parameter contributes to the scoring of the Method based
  # on the message argument types, including the message receiver.
  #
  class Signature
    include Comparable

    # The Module that the Signature is bound to.
    attr_accessor :mod

    # True if the signature is bound to the class.          
    attr_accessor :class_method 

    # The name of the method.
    attr_accessor :name

    # The list of Parameters, self is included at position 0.         
    attr_accessor :parameter

    # The minimum # of arguments for this signature.
    attr_accessor :min_args

    # The maximum # of arguments for this signature.
    # May be nil, if this Signature accepts restargs.
    attr_accessor :max_args
                          
    # The "*args" parameter or nil.      
    attr_accessor :restarg

    # The first Parameter with a default value.
    attr_accessor :default

    # The file where this Signature is specified.
    attr_accessor :file

    # The line in the file where this Signature is specified.
    attr_accessor :line

    # Defines level of verbosity during processing.
    attr_accessor :verbose

    # Initialize a new Signature.
    def initialize(*opts)
      opts = Hash[*opts]

      @mod = opts[:mod]
      @name = opts[:name]
      @class_method = false
      @parameter = [ ]
      @min_args = 0
      @max_args = 0
      @restarg = nil
      @default = nil

      @multimethod = nil

      @verbose = nil

      @score = { }

      # Handle a string representation of a signature.
      case params = opts[:string]
      when String
        scan_string(params)
      end

      # Handle other parameters.
      case params = opts[:parameter]
      when Array
        scan_parameters(params)
      when String
        scan_parameters_string(params)
      end
    end
    

    # Compares two Signature objects.
    def <=>(s)
      x = @name.to_s <=> s.name.to_s 
      x = (! @class_method == ! s.class_method ? 0 : 1) if x == 0
      x = @parameter <=> s.parameter if x == 0
      # $stderr.puts "#{to_s} <=> #{s.to_s} => #{x.inspect}"
      x
    end


    # Returns the bound Module.
    def mod
      # THREAD CRITICAL BEGIN
      if @mod && @mod.kind_of?(String)
        @mod = Table.instance.name_to_object(@mod, 
                                              nil, 
                                              file, line)
      end
      # THREAD CRITICAL END

      @mod
    end


    # Scan a string as a Signature, e.g.: "def foo(A a, x = true, *restargs)"
    def scan_string(str, need_names = true)

      str.sub!(/\A\s+/, '')

      if md = /\A(\w+(::\w+)*)#(\w+)/.match(str)
        str = md.post_match
        @mod = md[1] unless @mod
        @name = md[3]
      elsif md = /\A(\w+(::\w+)*)\.(\w+)/.match(str)
        str = md.post_match
        @mod = md[1] unless @mod
        @class_method = true
        @name = md[3]
      elsif md  = /\A((\w+(::\w+)*)\s+)?def\s+(self\.)?(\w+)/.match(str)
        str = md.post_match
        @mod = md[2] unless @mod
        @class_method = ! ! md[4]
        @name = md[5]
      else
        raise NameError, "Syntax error in multimethod signature at #{str.inspect}"
      end

      # Resolve mod name.
      # FIXME!

      # Add self parameter.
      add_self

      # Parse parameter list.
      if md = /\A\(/.match(str)
        str = md.post_match

        str = scan_parameters_string(str, need_names)

        $stderr.puts "  str=#{str.inspect}" if @verbose

        if md = /\A\)/.match(str)
          str = md.post_match
        else
          raise NameError, "Syntax error in multimethod parameters expected ')' at #{str.inspect}"
        end
      end
      
      str
    end


    # Scan the parameter string of a Signature:
    #
    #   "A a, x = true, *restargs"
    def scan_parameters_string(str, need_names = true)
      # @verbose = true

      # Add self parameter at front.
      add_self

      $stderr.puts "scan_parameters_string(#{str.inspect})" if @verbose

      until str.empty?
        # Scan parameter
        p = Parameter.new
        p.verbose = @verbose
        str = p.scan_string(str)
        add_parameter(p)
        $stderr.puts "  params=#{parameter_to_s}" if @verbose       

        # Parse , or )
        str.sub!(/\A\s+/, '')
        if ! str.empty? 
          if md = /\A,/s.match(str)
            str = md.post_match
          elsif md = /\A\)/s.match(str)
            $stderr.puts "  DONE: #{to_s}\n  Remaining: #{str.inspect}" if @verbose
            break
          else
            raise NameError, "Syntax error in multimethod parameters: expected ',' or ')' at #{str.inspect}"
          end
        end
 
      end

      $stderr.puts "scan_parameters_string(...): DONE: #{to_s}\n  Remaining: #{str}" if @verbose

      str
    end


    # Scan a programmatic Parameter list:
    #
    #   [ A, :a, B, :b, :c, '*d' ]
    #
    def scan_parameters(params)
      # Add self parameter at front.
      add_self

      until params.empty?
        name = nil
        type = nil
        restarg = false
        default = nil
        
        if x = params.shift
          case x
          when Class
            type = x
          else
            name = x
          end
        end

        if ! name && (x = params.shift)
          name = x
        end

        raise("Parameter name expected, found #{name.inspect}") unless name.kind_of?(String) || name.kind_of?(Symbol)
        raise("Parameter type expected, found #{type.inspect}") unless type.kind_of?(Module) || type.nil?

        p = Parameter.new(name, type, default)
        add_parameter(p)
      end

    end
    

    # Add the implicit "self" parameter at the front of the Parameter list.
    def add_self
      add_parameter(Parameter.new('self', mod)) if @parameter.empty?
    end

    
    # Adds a new Parameter.
    def add_parameter(p)
      if p.restarg
        raise("Too many restargs") if @restarg
        @restarg = p
        @max_args = nil
      end
      if p.default
        (@default ||= [ ]).push(p)
      end

      p.i = @parameter.size
      @parameter.push(p)
      p.signature = self

      unless p.default || p.restarg
        @min_args = @parameter.size
      end

      unless @restarg
        @max_args = @parameter.size
      end
    end


    # Score of this Signature based on the argument types.
    #
    # The score is an Array of values that when sorted against 
    # other Signature scores will
    # place the best matching Signature at the top of the list.
    def score(args)
      
      if @min_args > args.size
        # Not enough args
        score = nil
      elsif @max_args && @max_args < args.size
        # Too many args?
        # $stderr.puts "max_args = #{@max_args}, args.size = #{args.size}"
        score = nil
      else
        # Interpret how close the argument type is to the parameter's type.
        i = -1
        score = args.collect{|a| parameter_at(i = i + 1).score(a)}

        # Handle score for trailing restargs.
        if @restarg || @default
          while (i = i + 1) < @parameter.size
            # $stderr.puts "  Adding score i=#{i}"
            score << parameter_at(i).score(NilClass)
          end
        end

        # If any argument cannot match, avoid this method.
        score = nil if score.index(nil)
      end

      # if true || @name =~ /_bar$/
      #   $stderr.puts "    Method: score #{self.to_s} #{args.inspect} => #{score.inspect}"
      # end

      score
    end
    

    # Score of this Signature using a cache.
    def score_cached(args)
      unless x = @score[args]
        x = @score[args] =
          score(args)
      end
      x
    end



    # Returns the Parameter at argument position i.
    # If the Signature has a restarg, it will be used for
    # argument postitions past the end of the Parameter list.
    def parameter_at(i)
      if i >= @parameter.size && @restarg
        @restarg
      else
        @parameter[i]
      end
    end

 
    # Returns a String representing this Signature.
    def to_s(name = nil)
      name ||= @name || '_'
      p = @parameter.clone
      rcvr = p.shift
      "#{rcvr.type.name}##{name}(#{parameter_to_s(p)})"
    end


    # Returns a String representing this Signature's Parameters.
    def parameter_to_s(p = nil)
      p ||= @parameter
      p.collect{|x| x.to_s}.join(', ')
    end


    # Returns a String representing this Signature's definition in Ruby syntax.
    def to_ruby_def(name = nil)
      name ||= @name || '_'
      "def #{name}(#{to_ruby_arg})"
    end


    # Returns a String representing this Signature's definition in Ruby Doc syntax.
    def to_ruby_signature(name = nil)
      name ||= @name || '_'
      p = @parameter.clone
      rcvr = p.shift
      m = mod
      "#{m && m.name}##{name}(#{to_ruby_arg})"
    end


    # Returns a String representing this Signature's definition parameters in Ruby syntax.
    def to_ruby_arg
      x = @parameter.clone
      x.shift
      x.collect{|x| x.to_ruby_arg}.join(', ')
    end

    # Calls #to_s.
    def inspect
      to_s
    end

  end # class
end # module


