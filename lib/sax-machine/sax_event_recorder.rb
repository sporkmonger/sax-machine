module SAXMachine
  class SAXEventRecorder < SAXHandler
    def initialize(nsstack)
      super(nil, nsstack)
      @events = []
    end

    def object
      # First and last belong to the parent element
      @events[1..-2]
    end

    def start_element(name, attrs = [])
      @nsstack = NSStack.new(@nsstack, attrs)
      prefix, name = name.split(':', 2)
      prefix, name = nil, prefix unless name
      @events << [:start_element, @nsstack[prefix], name, attrs]
    end

    def end_element(name)
      prefix, name = name.split(':', 2)
      prefix, name = nil, prefix unless name
      @events << [:end_element, @nsstack[prefix], name]
      @nsstack = @nsstack.pop
    end

    def characters(string)
      @events << [:chars, string]
    end

    def sax_config
      raise
    end
  end
end
