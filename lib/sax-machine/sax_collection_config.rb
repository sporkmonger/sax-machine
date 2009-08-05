module SAXMachine
  class SAXConfig
    
    class CollectionConfig
      attr_reader :name
      attr_reader :default_xmlns
      
      def initialize(name, options)
        @name   = name.to_s
        @class  = options[:class]
        @as     = options[:as].to_s
        @xmlns  = case options[:xmlns]
                  when Array then options[:xmlns]
                  when String then [options[:xmlns]]
                  else nil
                  end
        @default_xmlns = options[:default_xmlns]
      end
      
      def handler(nsstack)
        if nsstack.nil? || nsstack[''] == ''
          nsstack = NSStack.new(nsstack, nsstack)
          nsstack[''] = @default_xmlns
        end
        SAXHandler.new(@class.new, nsstack)
      end
      
      def accessor
        as
      end
      
      def xmlns_match?(ns)
        @xmlns.nil? || @xmlns.include?(ns)
      end
      
    protected
      
      def as
        @as
      end
      
      def class
        @class || @name
      end      
    end
    
  end
end
