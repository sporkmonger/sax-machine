require "sax-machine/sax_element_config"
require "sax-machine/sax_collection_config"

module SAXMachine
  class SAXConfig
    attr_reader :top_level_elements, :collection_elements

    def initialize
      @top_level_elements  = {}
      @collection_elements = {}
    end

    def add_top_level_element(name, options)
      @top_level_elements[name.to_s] ||= []
      @top_level_elements[name.to_s] << ElementConfig.new(name, options)
    end

    def add_collection_element(name, options)
      @collection_elements[name.to_s] ||= []
      @collection_elements[name.to_s] << CollectionConfig.new(name, options)
    end

    def collection_config(name, nsstack)
      prefix, name = name.split(':', 2)
      prefix, name = nil, prefix unless name  # No prefix
      namespace = nsstack[prefix]

      (@collection_elements[name.to_s] || []).detect { |ce|
        ce.name.to_s == name.to_s &&
        ce.xmlns_match?(namespace)
      }
    end

    def element_configs_for_attribute(name, attrs)
      name = name.split(':', 2).last
      (@top_level_elements[name.to_s] || []).select do |element_config|
        element_config.has_value_and_attrs_match?(attrs)
      end
    end

    def element_config_for_tag(name, attrs, nsstack)
      prefix, name = name.split(':', 2)
      prefix, name = nil, prefix unless name  # No prefix
      namespace = nsstack[prefix]

      (@top_level_elements[name.to_s] || []).detect do |element_config|
        element_config.xmlns_match?(namespace) &&
        element_config.attrs_match?(attrs)
      end
    end

  end
end
