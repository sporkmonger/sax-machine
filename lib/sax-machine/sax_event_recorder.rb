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
      @events << [:start_element, "", name, attrs]
    end

    def end_element(name)
      @events << [:end_element, "", name]
    end

    def characters(string)
      @events << [:chars, string]
    end

    def sax_config
      raise
    end
  end
end
