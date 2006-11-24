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

    def initialize(name, type = nil, default = nil, restarg = false)
      # $stderr.puts "initialize(#{name.inspect}, #{type}, #{restarg.inspect})"
      if name
        name = name.to_s
        if name.sub!(/^\*/, '')
          restarg = true
        end  
        
        name = name.intern unless name.kind_of?(Symbol)
      end

      @name = name
      @i = nil
      @type = type || Kernel
      @default = default
      @restarg = restarg

      @method = @signature = nil
    end


    def <=>(p)
      x = @type <=> p.type 
      x = ! @restarg == ! p.restarg ? 0 : 1 if x == 0
      x = ! @default == ! p.default ? 0 : 1 if x == 0
      # $stderr.puts "#{to_s} <=> #{p.to_s} => #{x.inspect}"
      x
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

