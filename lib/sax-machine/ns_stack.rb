module SAXMachine
  class NSStack < Hash
    XMLNS = 'xmlns'

    def initialize(parent=nil, attrs=[])
      # Initialize
      super()
      @parent = parent

      # Parse attributes
      attrs.each do |attr|
        if attr.kind_of?(Array)
          k, v = attr
          case k
          when XMLNS then self[EMPTY_STRING] = v
          when /^xmlns:(.+)/ then self[$1] = v
          end
        end
      end
    end

    # Lookup
    def [](name)
      if (ns = super(name.to_s))
        # I've got it
        ns
      elsif @parent
        # Parent may have it
        @parent[name]
      else
        # Undefined, empty namespace
        EMPTY_STRING
      end
    end

    def pop
      @parent
    end
  end
end
