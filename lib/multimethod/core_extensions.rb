module Multimethod

  module ObjectExtension
    def self.append_features(base) # :nodoc:
      # puts "append_features{#{base}}"
      super
      base.extend(ClassMethods)
    end

    module ClassMethods
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
    end
  end # class
end # module


# Add to Module
Object.class_eval do
  include Multimethod::ObjectExtension
end



