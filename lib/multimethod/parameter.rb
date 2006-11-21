module Multimethod
  class Parameter
    RESTARG_SCORE = 9999

    attr_accessor :name
    attr_accessor :i
    attr_accessor :type
    attr_accessor :default
    attr_accessor :restarg

    attr_accessor :method

    def initialize(name, type = nil, default = nil, restarg = false)
      # $stderr.puts "initialize(#{name.inspect}, #{type}, #{restarg.inspect})"
      name = name.to_s
      if name.sub!(/^\*/, '')
        restarg = true
      end  

      name = name.intern unless name.kind_of?(Symbol)
      @name = name
      @i = nil
      @type = type || Kernel
      @default = default
      @restarg = restarg
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
        @type = @method.multimethod.table.name_to_object(@type, @method.mod, @method)
      end
      @type
    end


    def to_s
      @restarg ? "*#{@name}" : @name
    end


    def to_s_long
      "#{@type} #{to_ruby}"
    end


    def to_ruby
      "#{to_s}#{@default ? ' = ' + @default : ''}"
    end

  end # class
end # module

