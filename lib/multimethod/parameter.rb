module Multimethod

  # Represents a Parameter in a Signature.
  #
  # A Parameter has a name, type and position.
  #
  # Parameters may also have a default value or may be a restarg, a parameter that
  # collects all remaining arguments.
  #
  # Restarg parameters have a lower score than other arguments.
  #
  # Unlike Ruby parameters, Parameters are typed.  Unspecified Parameter types default to Kernel.
  #
  class Parameter
    include Comparable

    # The score used for all restarg Parameters.
    RESTARG_SCORE = 9999
    
    # The Parameter name.
    attr_accessor :name

    # The Parameter's offset in the Signature's parameter list.
    # Parameter 0 is the implied "self" Parameter.
    attr_accessor :i

    # The Paremeter's type, defaults to Kernel.
    attr_accessor :type

    # The Parameter's default value expression.
    attr_accessor :default

    # True if the Parameter is a restarg: e.g.: "*args"
    attr_accessor :restarg

    # The Parameter's owning Signature.
    attr_accessor :signature

    # Defines level of verbosity during processing.
    attr_accessor :verbose

    # Initialize a new Parameter.
    def initialize(name = nil, type = nil, default = nil, restarg = false)
      # $stderr.puts "initialize(#{name.inspect}, #{type}, #{default.inspect}, #{restarg.inspect})"
      if name
        # Default type if name is specified
        type ||= Kernel
      end

      @i = nil
      @type = type
      @default = default
      @restarg = restarg
      @verbose = false

      self.name = name # may affect @restarg

      @signature = nil
    end


    def name=(name)
      if name
        name = name.to_s
        if name.sub!(/\A\*/, '')
          @restarg = true
        end
        
        name = name.intern
      end
      @name = name
    end

    # Compare two Parameters.
    # Only type and restarg are significant.
    def <=>(p)
      x = @type <=> p.type 
      x = ! @restarg == ! p.restarg ? 0 : 1 if x == 0
      # x = ! @default == ! p.default ? 0 : 1 if x == 0
      # $stderr.puts "#{to_s} <=> #{p.to_s} => #{x.inspect}"
      x
    end


    # Scan a string for a Parameter specification.
    def scan_string(str, need_names = true)
      str.sub!(/\A\s+/, '')
      
      $stderr.puts "  str=#{str.inspect}" if @verbose
      
      if md = /\A(\w+(::\w+)*)\s+(\w+)/s.match(str)
        # $stderr.puts "   pre_match=#{md.pre_match.inspect}"
        # $stderr.puts "   md[0]=#{md[0].inspect}"
        str = md.post_match
        type = md[1]
        name = md[3]
      elsif md = /\A(\*?\w+)/s.match(str)
        # $stderr.puts "   pre_match=#{md.pre_match.inspect}"
        # $stderr.puts "   md[0]=#{md[0].inspect}"
        str = md.post_match
        type = nil
        name = md[1]
      else
        raise NameError, "Syntax error in multimethod parameter: expected type and/or name at #{str.inspect}"
      end
      
      $stderr.puts "  type=#{type.inspect}" if @verbose       
      $stderr.puts "  name=#{name.inspect}" if @verbose       
      
      # Parse parameter default.
      if md = /\A\s*=\s*/.match(str)
        str = md.post_match
        
        in_paren = 0
        default = ''
        until str.empty?
          # $stderr.puts "    default: str=#{str.inspect}"
          # $stderr.puts "    default: params=#{parameter_to_s}"
          
          if md = /\A(\s+)/s.match(str)
            str = md.post_match
            default = default + md[1]
          end
          
          if md = /\A("([^"\\]|\\.)*")/s.match(str)
            str = md.post_match
            default = default + md[1]
          elsif md = /\A('([^'\\]|\\.)*')/s.match(str)
            str = md.post_match
            default = default + md[1]
          elsif md = /\A(\()/.match(str)
            str = md.post_match
            in_paren = in_paren + 1
            default = default + md[1]
          elsif in_paren > 0 && md = /\A(\))/s.match(str)
            str = md.post_match
            in_paren = in_paren - 1
            default = default + md[1]
          elsif md = /\A(\))/s.match(str)
            break
          elsif in_paren == 0 && md = /\A,/s.match(str)
            break
          elsif md = /\A(\w+)/s.match(str)
            str = md.post_match
            default = default + md[1]
          elsif md = /\A(.)/s.match(str)
            str = md.post_match
            default = default + md[1] 
          end
        end
      end
      
      self.name = name unless @name
      type ||= Kernel
      self.type = type unless @type
      self.default = default unless @default

      str
    end


    # Returns the score of this Parameter matching an argument type.
    #
    # The score is determined by the relative distance of the Parameter
    # to the argument type.  A lower distance means a tighter match
    # of this Parameter.
    #
    # Restarg Parameters score lower, see RESTARG_SCORE.
    def score(arg)
      return RESTARG_SCORE if @restarg
      score = all_types(arg).index(type_object)
    end


    # Returns a list of all parent Modules of an argument type,
    # including itself, in most-specialized
    # to least-specialized order.
    def all_types(arg_type)
      arg_type.ancestors
    end


    # Resolves type by name
    def type_object
      if @type.kind_of?(String)
        @type = Table.instance.name_to_object(@type, 
                                              @signature.mod, 
                                              @signature.file, 
                                              @signature.line)
      end
      @type
    end


    # Returns a String representing this Parameter in a Signature string.
    def to_s
      "#{@type} #{to_ruby_arg}"
    end
    

    # Return a String representing this Parameter as a Ruby method parameter.
    def to_ruby_arg
      "#{to_s_name}#{@default ? ' = ' + @default : ''}"
    end


    # Return a String representing this Parameter's name.
    # Restargs will be prefixed with '*'.
    def to_s_name
      (@restarg ? "*" : '') + (@name.to_s || "_arg_#{@i}")
    end

  end # class
end # module

