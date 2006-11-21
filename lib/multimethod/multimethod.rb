module Multimethod
  class Multimethod

    attr_accessor :name
    attr_accessor :method
    attr_accessor :table

    def initialize(name, *opts)
      raise NameError, "multimethod name not specified" unless name && name.to_s.size > 0
 
      @name = name
      @name_i = 0
      @method = [ ]
      @dispatch = { }

      @lookup_method = { }
    end


    def gensym(name = nil)
      name ||= @name
      "_multimethod_#{@name_i = @name_i + 1}_#{name}"
    end


    def new_method(mod, *args)
      m = Method.new(mod, gensym, *args)
      add_method(m)
      m
    end


    def add_method(method)
      # THREAD CRITICAL BEGIN
      @method.push(method)
      method.multimethod = self
      @lookup_method = { } # flush cache
      # THREAD CRITICAL END
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
      rcvr.send(meth.name, *args)
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
      
      # $stderr.puts "score_methods(#{args.inspect}) => \n#{scores.inspect}"

      scores
    end


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

