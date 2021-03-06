module SAXMachine
  class SAXConfig
    class ElementConfig
      attr_reader :name, :setter, :data_class

      def initialize(name, options)
        @name = name.to_s

        if options.has_key?(:with)
          # for faster comparisons later
          @with = options[:with].to_a.flatten.collect {|o| o.to_s}
        else
          @with = nil
        end

        if options.has_key?(:value)
          @value = options[:value].to_s
        else
          @value = nil
        end

        @as = options[:as]
        @collection = options[:collection]

        if @collection
          @setter = "add_#{options[:as]}"
        else
          @setter = "#{@as}="
        end
        @data_class = options[:class]
        @required = options[:required]

        @xmlns = case options[:xmlns]
                 when Array then options[:xmlns]
                 when String then [options[:xmlns]]
                 else nil
                 end
      end

      def column
        @as || @name.to_sym
      end

      def required?
        @required
      end

      def value_from_attrs(attrs)
        pair = attrs.detect { |k, v| k == @value }
        pair ? pair.last : nil
      end

      def attrs_match?(attrs)
        if @with
          if attrs.nil?
            # If no attributes, match only if the :with clause is empty.
            @with.empty?
          else
            # Attributes must match :with clause.
            attrs.include?(@with)
          end
        else
          true
        end
      end

      def has_value?
        !@value.nil?
      end

      def has_value_and_attrs_match?(attrs)
        has_value? && attrs_match?(attrs)
      end

      def xmlns_match?(ns)
        @xmlns.nil? || @xmlns.include?(ns)
      end

      def collection?
        @collection
      end
    end
  end
end
