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
        if @default_xmlns && @xmlns && !@xmlns.include?('')
          @xmlns << ''
        end
        @record_events = options[:events]
      end
      
      def handler(nsstack)
        if @default_xmlns && (nsstack.nil? || nsstack[''] == '')
          nsstack = NSStack.new(nsstack, nsstack)
          nsstack[''] = @default_xmlns
        end
        unless @record_events
          SAXHandler.new(@class.new, nsstack)
        else
          SAXEventRecorder.new(nsstack)
        end
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
