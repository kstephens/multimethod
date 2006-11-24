module Multimethod
  class Parameter
    include Comparable

    RESTARG_SCORE = 9999

    attr_accessor :name
    attr_accessor :i
    attr_accessor :type
    attr_accessor :default
    attr_accessor :restarg

    attr_accessor :method
    attr_accessor :signature
    attr_accessor :verbose

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

      @method = @signature = nil
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


    def <=>(p)
      x = @type <=> p.type 
      x = ! @restarg == ! p.restarg ? 0 : 1 if x == 0
      x = ! @default == ! p.default ? 0 : 1 if x == 0
      # $stderr.puts "#{to_s} <=> #{p.to_s} => #{x.inspect}"
      x
    end


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


    def score(arg)
      return RESTARG_SCORE if @restarg
      score = all_types(arg).index(type_object)
    end


    def all_types(arg)
      arg.ancestors
    end


    def type_object
      if @type.kind_of?(String)
        @type = Table.instance.name_to_object(@type, 
                                              @signature.mod, 
                                              @method && @method.file, 
                                              @method && @method.line)
      end
      @type
    end


    def to_s
      "#{@type} #{to_ruby_arg}"
    end
    

    def to_ruby_arg
      "#{to_s_name}#{@default ? ' = ' + @default : ''}"
    end


    def to_s_name
      (@restarg ? "*" : '') + (@name.to_s || "_arg_#{@i}")
    end

  end # class
end # module

