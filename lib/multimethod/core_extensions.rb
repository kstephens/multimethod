module Multimethod

  # See Multimethod::ObjectExtension::ClassMethods
  module ObjectExtension
    def self.append_features(base) # :nodoc:
      # puts "append_features{#{base}}"
      super
      base.extend(ClassMethods)
    end


    # This module is included into Object
    # It is the "glue" for Multmethod.
    module ClassMethods
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
      # Interfaces to Multimethod::Table.instance.
      def multimethod(body, file = nil, line = nil)
        unless file && line
          fileline = caller(1)[0]
          if fileline && md = /^(.*):(\d+)$/.match(fileline)
            file, line = md[1], md[2].to_i
            
            newlines = 0
            body.gsub(/\n/s){|x| newlines = newlines + 1}
            line -= newlines
          end
          
          # $stderr.puts "file = #{file.inspect}, line = #{line.inspect}"
        end
        
        ::Multimethod::Table.instance.install_method(self, body, file, line)
      end

      # Removes a Multimethod using a signature:
      #
      #    class A
      #      remove_multimethod "def foo(A x)"
      #    end
      def remove_multimethod(signature)
        ::Multimethod::Table.instance.remove_method(signature)
      end

    end # mixin
  end # class
end # module


# Add to Object
Object.class_eval do
  include Multimethod::ObjectExtension
end



