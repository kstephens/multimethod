module Multimethod

  class Method
    attr_accessor :mod
    attr_accessor :name
    attr_accessor :parameter

    attr_accessor :min_args
    attr_accessor :max_args
    attr_accessor :restarg
    attr_accessor :default

    attr_accessor :multimethod
    attr_accessor :file
    attr_accessor :line

    def initialize(mod, name, params)
      raise NameError, "multimethod method name not specified" unless name && name.to_s.size > 0

      name = Multimethod.normalize_name(name)

      @mod = mod
      @name = name
      @parameter = [ ]
      @min_args = 0
      @max_args = 0
      @restarg = nil
      @default = nil

      @score = { }

      # Add self parameter at front.
      add_parameter(Parameter.new('self', mod))

      # Handle other parameters.
      case params
      when Array
        scan_parameters(params)
      when String
        scan_parameters_string(params)
      end
    end
    

    # For sort
    def <=>(x)
      0
    end


    def scan_parameters_string(params)

      #$stderr.puts "scan_parameters_string(#{params.inspect})"

      str = params.clone

      until str.empty?
        name = nil
        type = nil
        default = nil
        
        str.sub!(/^\s+/, '')

        # $stderr.puts "  str=#{str.inspect}"
        
        if md = /^(\w+(::\w+)*)\s+(\w+)/i.match(str)
          str = md.post_match
          type = md[1]
          name = md[3]
        elsif md = /^(\*?\w+)/i.match(str)
          str = md.post_match
          type = nil
          name = md[1]
        else
          raise NameError, "Syntax error in multimethod parameters: #{params.inspect} before #{str.inspect}"
        end
        
        if md = /^\s*=\s*([^,]+)/.match(str)
          str = md.post_match
          default = md[1]
        end
        
        
        str.sub!(/^\s+/, '')
        if ! str.empty? 
          if md = /^,/.match(str)
            str = md.post_match
          else
            raise NameError, "Syntax error in multimethod parameters: expected ',' before #{str.inspect}"
          end
        end
        
        p = Parameter.new(name, type, default)
        add_parameter(p)
      end
    end


    def scan_parameters(params)
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
      p.method = self

      unless p.default || p.restarg
        @min_args = @parameter.size
      end

      unless @restarg
        @max_args = @parameter.size
      end
    end


    def score_cached(args)
      unless x = @score[args]
        x = @score[args] =
          score(args)
      end
      x
    end


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
    

    def parameter_at(i)
      if i >= @parameter.size && @restarg
        @restarg
      else
        @parameter[i]
      end
    end

 
    def parameter_to_s(p = nil)
      p ||= @parameter
      p.collect{|x| x.to_s_long}.join(', ')
    end

    def to_s(name = nil)
      name ||= @name
      p = @parameter.clone
      rcvr = p.shift
      "#{rcvr.type.name}##{name}(#{parameter_to_s(p)})"
    end

    def to_ruby
      "def #{name}(#{to_s_arg})"
    end

    def to_s_arg
      x = @parameter.clone
      x.shift
      x.collect{|x| x.to_ruby}.join(', ')
    end

    def inspect
      to_s
    end
  end # class
end # module


