module SAXMachine
  class SAXConfig
    
    class CollectionConfig
      attr_reader :name
      
      def initialize(name, options)
        @name   = name.to_s
        @class  = options[:class]
        @as     = options[:as].to_s
        @xmlns  = case options[:xmlns]
                  when Array then options[:xmlns]
                  when String then [options[:xmlns]]
                  else nil
                  end
      end
      
      def handler(nsstack)
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
